import 'dart:math';

import 'package:bech32/bech32.dart';
import 'package:bip340/bip340.dart' as bip340;
import 'package:hex/hex.dart';
import 'package:uuid/uuid.dart';

class Keys {
  String getPublicKey(String privateKey) {
    return bip340.getPublicKey(privateKey);
  }

  KeyPair generatePrivateKey() {
    String privKey = _getSecureRandomHex(32);
    String pubKey = getPublicKey(privKey);

    String privKeyHr = _encodeBech32(privKey, 'nsec');
    String pubKeyHr = _encodeBech32(pubKey, 'npub');

    return KeyPair(privKey, pubKey, privKeyHr, pubKeyHr);
  }

  String npubEncode(String key) {
    return _encodeBech32(key, 'npub');
  }

  String nsecEncode(String key) {
    return _encodeBech32(key, 'nsed');
  }

  List<String> decodeKey(String key) {
    return _decodeBech32(key);
  }

  /// Generate UUID
  String getUuid() {
    const uuid = Uuid();
    return uuid.v4();
  }

  String _getSecureRandomHex(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return HEX.encode(values);
  }

  /// converts a hex string to bech32
  /// hrp = human readable part
  /// returns bech32 string
  String _encodeBech32(String myHex, String hrp) {
    var bytes = HEX.decode(myHex);

    // Convert the 8-bit words to 5-bit words.
    List<int> fiveBitWords = _convertBits(bytes, 8, 5, true);

    var bech32String = bech32.encode(Bech32(hrp, fiveBitWords));

    return bech32String;
  }

  List<int> _convertBits(List<int> data, int fromBits, int toBits, bool pad) {
    int acc = 0;
    int bits = 0;
    List<int> ret = [];
    for (int value in data) {
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        ret.add((acc >> bits) & (1 << toBits) - 1);
      }
    }
    if (pad) {
      if (bits > 0) {
        ret.add(acc << (toBits - bits) & (1 << toBits) - 1);
      }
    } else if (bits >= fromBits || (acc & ((1 << bits) - 1)) != 0) {
      throw Exception('Invalid padding');
    }
    return ret;
  }

  /// converts a bech32 string to hex
  /// returns a list of [hex, hrp]
  List<String> _decodeBech32(String myBech32) {
    Bech32Codec codec = const Bech32Codec();
    Bech32 bech32 = codec.decode(
      myBech32,
      myBech32.length,
    );

    // Convert the 5-bit words to 8-bit words.
    List<int> eightBitWords = _convertBits(bech32.data, 5, 8, false);

    return [HEX.encode(eightBitWords), bech32.hrp];
  }
}

class KeyPair {
  /// [privateKey] is the private key in hex
  String privateKey;

  /// [publicKey] is the public key in hex
  String publicKey;

  /// [privateKeyHr] is the private key in bech32 with hrp 'nsec'
  String privateKeyHr;

  /// [publicKeyHr] is the public key in bech32 with hrp 'npub'
  String publicKeyHr;

  KeyPair(this.privateKey, this.publicKey, this.privateKeyHr, this.publicKeyHr);

  // to json
  Map<String, dynamic> toJson() => {
        'privateKey': privateKey,
        'publicKey': publicKey,
        'privateKeyHr': privateKeyHr,
        'publicKeyHr': publicKeyHr,
      };

  // from json
  factory KeyPair.fromJson(Map<String, dynamic> json) => KeyPair(
        json['privateKey'],
        json['publicKey'],
        json['privateKeyHr'],
        json['publicKeyHr'],
      );
}
