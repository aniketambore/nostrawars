import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bip340/bip340.dart';
import 'package:crypto/crypto.dart';
import 'package:kepler/kepler.dart';
import 'package:nostr/nostr.dart';
import 'package:pointycastle/export.dart';

class Nip04 {
  final String privKey;
  Nip04(this.privKey);

  Future<String> decryptContent(Event event) async {
    print('[+] nip04.dart | Nip04 | decryptContent()');
    final fragments = event.content.split("?iv=");
    if (fragments.length != 2) {
      throw Exception("bad content");
    }

    final cipher = fragments[0];
    final iv = fragments[1];

    return await decrypt(privKey, '02${event.pubkey}', cipher, iv);
  }

  Future<String> decrypt(
    String privateKeyHex,
    String publicKeyHex,
    String cipherTextBase64,
    String ivBase64,
  ) async {
    print('[+] nip04.dart | Nip04 | decrypt()');

    final cipherText = base64.decode(cipherTextBase64);
    final iv = base64.decode(ivBase64);
    final sharedSecret = Kepler.byteSecret(privateKeyHex, publicKeyHex);
    final key = Uint8List.fromList(sharedSecret[0]);

    final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv), null);

    final cipherImpl =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));
    cipherImpl.init(false, params);

    int ptr = 0;
    final buffer = Uint8List(cipherText.length);
    while (ptr < cipherText.length - 16) {
      ptr += cipherImpl.processBlock(cipherText, ptr, buffer, ptr);
    }
    ptr += cipherImpl.doFinal(cipherText, ptr, buffer, ptr);

    final rawData = buffer.sublist(0, ptr).toList();
    return const Utf8Decoder().convert(rawData);
  }

  String encrypt(String receiverPubKey, String plainText) {
    try {
      Uint8List uintInputText = const Utf8Encoder().convert(plainText);
      final encryptedString = _encryptRaw(receiverPubKey, uintInputText);
      return encryptedString;
    } catch (e) {
      print('[!] Line:64 | encrypt() | nip04.dart | e:$e');
      rethrow;
    }
  }

  String _encryptRaw(String receiverPubKey, Uint8List uintInputText) {
    try {
      final secretIV = Kepler.byteSecret(privKey, '02$receiverPubKey');
      final key = Uint8List.fromList(secretIV[0]);

      final random = Random();
      final iv =
          Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));

      final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      );

      final cipherImpl = PaddedBlockCipherImpl(
        PKCS7Padding(),
        CBCBlockCipher(AESEngine()),
      );

      cipherImpl.init(
        true, // means to encrypt
        params,
      );

      // allocate space
      final Uint8List outputEncodedText = Uint8List(uintInputText.length + 16);

      var offset = 0;
      while (offset < uintInputText.length - 16) {
        offset += cipherImpl.processBlock(
            uintInputText, offset, outputEncodedText, offset);
      }

      //add padding
      offset +=
          cipherImpl.doFinal(uintInputText, offset, outputEncodedText, offset);
      final Uint8List finalEncodedText = outputEncodedText.sublist(0, offset);

      String stringIv = base64.encode(iv);
      String outputPlainText = base64.encode(finalEncodedText);
      outputPlainText = "$outputPlainText?iv=$stringIv";
      return outputPlainText;
    } catch (e) {
      print('[!] Line:133 | _encryptRaw() | nip04.dart | e:$e');
      rethrow;
    }
  }

  String getShaId(String pubkey, String createdAt, String kind, String strTags,
      String content) {
    String buf = '[0,"$pubkey",$createdAt,$kind,[$strTags],"$content"]';
    var bufInBytes = utf8.encode(buf);
    var value = sha256.convert(bufInBytes);
    return value.toString();
  }

  String mySign(String privateKey, String msg) {
    String randomSeed = getRandomPrivKey();
    randomSeed = randomSeed.substring(0, 32);
    return sign(privateKey, msg, randomSeed);
  }

  String getRandomPrivKey() {
    FortunaRandom fr = FortunaRandom();
    final sGen = Random.secure();
    fr.seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (_) => sGen.nextInt(255)))));

    BigInt randomNumber = fr.nextBigInteger(256);
    String strKey = randomNumber.toRadixString(16);
    if (strKey.length < 64) {
      int numZeros = 64 - strKey.length;
      for (int i = 0; i < numZeros; i++) {
        strKey = "0$strKey";
      }
    }
    return strKey;
  }
}

String getPublicKeyFromPrivate(String privateKey) {
  var keyParams = ECCurve_secp256k1();
  final kp = Kepler.loadPrivateKey(privateKey);
  final q = ECCurve_secp256k1().G * kp.d;
  final publicKey = ECPublicKey(q, keyParams);
  return Kepler.strinifyPublicKey(publicKey).substring(2);
}
