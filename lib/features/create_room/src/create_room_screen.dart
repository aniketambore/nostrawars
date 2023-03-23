// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:js/js.dart';
import 'package:nostrawars/features/game/game.dart';
import 'package:nostrawars/features/main_page/main_page.dart';
import 'package:nostrawars/component_library/component_library.dart';
import 'package:nostrawars/features/withdraw_sats/withdraw_sats.dart';
import 'package:nostrawars/nostr/nostr.dart';
import 'package:nostrawars/nostr/src/nostr_js.dart' as NostrJS;

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _relayUrl = 'wss://relay.damus.io';
  late KeyPair userKeys;
  final keys = Keys();
  bool connected = false;

  bool syn = false;
  bool synAck = false;
  bool ack = false;

  String synAckSha = '';

  bool gameStarted = false;
  late final MyGame _game;
  String opponentPlayer = '';

  void _closeRelay() {
    print(
        '[+] create_room_screen.dart | _CreateRoomScreenState | _closeRelay()');
    NostrJS.closeRelay();
  }

  Future<void> startGame(String gameText) async {
    Map<String, dynamic>? jsonData = gameTextParse(gameText);
    if (jsonData != null) {
      double? x = jsonData['x'];
      double? y = jsonData['y'];
      int? health = jsonData['health'];

      if (x != null && y != null && health != null) {
        final position = Vector2(x, y);
        final opponentHealth = health;
        print('x:$x, y:$y, health:$health');

        _game.updateOpponent(position: position, health: health);
        print(
          '[+] Receiving (opponent): x: ${position.x}, y: ${position.y}, health: $opponentHealth',
        );
        if (opponentHealth <= 5) {
          if (!_game.isGameOver) {
            _game.isGameOver = true;
            _game.onGameOver(true);
          }
        }
        // await Future.delayed(Duration.zero);
        // setState(() {});
      }
    }
  }

  Future<void> _initializeGame() async {
    _game = MyGame(onGameStateUpdate: (position, health) async {
      // Loop until the send succeeds if the payload is to notify defeat.
      do {
        sendDm(
          '{"x":${position.x},"y":${position.y},"health":$health}',
          opponentPlayer,
        );
        print(
          '[+] Sending (my): x: ${position.x}, y: ${position.y}, health: $health',
        );
        // // wait for a frame to avoid infinite rate limiting loops
        await Future.delayed(Duration.zero);
        setState(() {});
      } while (gameStarted && health <= 0 && connected);
    }, onGameOver: (playerWon) async {
      setState(() => gameStarted = false);
      _closeRelay();
      if (playerWon) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WithdrawSatsScreen(
              winnerNpub: userKeys.publicKeyHr,
            ),
          ),
        );
      } else {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: ((context) {
            return AlertDialog(
              title: const Text(
                  "You have been defeated, but don't give up, the Nostrawars galaxy needs you!"),
              actions: [
                TextButton(
                  onPressed: () async {
                    _closeRelay();
                    Navigator.of(context).pop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainPageScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Lobby'),
                ),
              ],
            );
          }),
        );
      }
    });
    // await for a frame so that the widget mounts
    // await Future.delayed(Duration.zero);
  }

  @override
  void initState() {
    print('[+] [initState() | create_room_screen.dart]');
    super.initState();
    _generateKeys();
    _initializeGame();
    if (mounted) {
      _connectRelays();
    }
  }

  void _generateKeys() {
    print('[+] [_generateKeys() | create_room_screen.dart]');
    userKeys = keys.generatePrivateKey();
    print('[+] userKeys: $userKeys');
  }

  // void _generateKeys() {
  //   print('[+] [_generateKeys() | create_room_screen.dart]');
  //   var sk1 =
  //       'f03b226e0c1dfde7b427971810e3bc366cd6cfbd0d3d822a26b817fcb8ae12e2';
  //   var pk1 =
  //       'b136202de82fb8f21129f3a5a4a3cf96b6d84dc243e80d8dd7c103e5649e1bcb';
  //   userKeys = KeyPair(sk1, pk1, keys.nsecEncode(sk1), keys.npubEncode(pk1));
  //   print("privKey: $sk1\npubkey: $pk1");
  // }

  void connectedCallback() {
    setState(() => connected = true);
  }

  void eventReceivedCallback(String plaintext, String opponentPk) async {
    print('[+] event received: plaintext: $plaintext');

    if (plaintext.isNotEmpty) {
      print('[+] gameStarted: $gameStarted');
      if (gameStarted) {
        startGame(plaintext);
        return;
      }

      List<String> parsedList = parseText(plaintext);
      if (parsedList.first == "SYN" && !syn && !synAck && !ack) {
        print(
          '[+] [_decrypt() | create_room_screen.dart]: SYN: ${parsedList.last}',
        );
        setState(() => syn = true);
        var bytes = utf8.encode(parsedList.last);
        var messageToSend = 'SYN-ACK:${sha256.convert(bytes)}';
        sendDm(messageToSend, opponentPk);
      } else if (parsedList.first == "ACK" &&
          parsedList.last == synAckSha &&
          syn &&
          synAck) {
        print(
          '[+] [_decrypt() | create_room_screen.dart]: ACK: ${parsedList.last}',
        );

        // await a frame to allow subscribing to a new channel in a realtime callback
        setState(() {
          ack = true;
          gameStarted = true;
          opponentPlayer = opponentPk;
        });

        print('[+] Game Loading... | create_room_screen.dart');
        // Future.delayed(const Duration(seconds: 3), () {
        //   setState(() {});
        //   _game.startNewGame();
        //   print('[+] Push to game screen');
        // });
        await Future.delayed(const Duration(seconds: 3));
        setState(() {});
        _game.startNewGame();
      }
    }
  }

  void _connectRelays() async {
    print(
        '[+] [create_room_screen.dart | _CreateRoomScreenState | _connectRelays()]');

    await NostrJS.connectToRelay(
      allowInterop(() => connectedCallback()),
      userKeys.privateKey,
      userKeys.publicKey,
      allowInterop((plaintext, opponentPk) =>
          eventReceivedCallback(plaintext, opponentPk)),
    );
  }

  List<String> parseText(String string) {
    List<String> parts = string.split(':');
    return parts;
  }

  Map<String, dynamic>? gameTextParse(String gameText) {
    try {
      Map<String, dynamic> parsedJson = jsonDecode(gameText);
      if (parsedJson is Map<String, dynamic>) {
        return parsedJson;
      } else {
        print('Error parsing JSON: unexpected data format');
        return null;
      }
    } catch (e) {
      print('Error parsing JSON: $e');
      return null;
    }
  }

  @override
  void dispose() {
    print('[+] main.dart | _CreateRoomScreenState | dispose()');
    super.dispose();
    print('[!] Line:434 | _closeRelay triggered');
    _closeRelay();
  }

  @override
  Widget build(BuildContext context) {
    return GameCursor(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/bg/1.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/bg/2.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/bg/3.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/bg/4.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: gameStarted
                  ? GameWidget(game: _game)
                  // ? gameOn()1
                  : CreateRoomCard(
                      npubEncode: userKeys.publicKeyHr,
                    ),
            ),
            const Positioned(
              bottom: 10,
              right: 10,
              child: Text('Made for #NostHack'),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleWidget(
                        borderColor: white,
                        shadowColor: santasGray10,
                        bgColor: connected ? carribeanGreen : flamingo,
                      ),
                      const SizedBox(
                        width: Spacing.small,
                      ),
                      Text(
                        _relayUrl,
                        style: const TextStyle(
                          fontSize: FontSize.medium,
                        ),
                      )
                    ],
                  ),
                  (!gameStarted)
                      ? ShowKeys(
                          npubEncode: userKeys.publicKeyHr,
                          nsecEncode: userKeys.privateKeyHr)
                      : Container(),
                  TextButton(
                    onPressed: () {
                      _closeRelay();
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleWidget(
                        borderColor: white,
                        shadowColor: santasGray10,
                        bgColor: syn ? carribeanGreen : flamingo,
                      ),
                      const SizedBox(
                        width: Spacing.small,
                      ),
                      const Text(
                        'SYN',
                        style: TextStyle(
                          fontSize: FontSize.medium,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: Spacing.small,
                  ),
                  Row(
                    children: [
                      CircleWidget(
                        borderColor: white,
                        shadowColor: santasGray10,
                        bgColor: synAck ? carribeanGreen : flamingo,
                      ),
                      const SizedBox(
                        width: Spacing.small,
                      ),
                      const Text(
                        'SYN-ACK',
                        style: TextStyle(
                          fontSize: FontSize.medium,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: Spacing.small,
                  ),
                  Row(
                    children: [
                      CircleWidget(
                        borderColor: white,
                        shadowColor: santasGray10,
                        bgColor: ack ? carribeanGreen : flamingo,
                      ),
                      const SizedBox(
                        width: Spacing.small,
                      ),
                      const Text(
                        'ACK',
                        style: TextStyle(
                          fontSize: FontSize.medium,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void sendDm(String message, String receiver) async {
    final pk2 = receiver;

    if (message.trim().isEmpty) return;

    print('[+] Sending to pubkey: $pk2');

    try {
      await NostrJS.sendDm(message, userKeys.privateKey, userKeys.publicKey,
          pk2, allowInterop((msg) => onPublishSuccess(msg)));
    } catch (e) {
      print('[+] sendDm error: $e');
    }
  }

  void onPublishSuccess(String message) {
    print('[+] relay has accepted our event');
    List<String> parsedList = parseText(message);
    if (parsedList.first == 'SYN-ACK') {
      setState(() {
        synAck = true;
        synAckSha = parsedList.last;
      });
    }
  }
}

class ShowKeys extends StatelessWidget {
  const ShowKeys({
    super.key,
    required this.npubEncode,
    required this.nsecEncode,
  });

  final String npubEncode;
  final String nsecEncode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: ExpandedElevatedButton(
        label: 'Keys',
        onTap: () async {
          await showDialog(
            context: context,
            builder: ((context) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: flamingo,
                    width: 2,
                  ),
                ),
                child: AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  backgroundColor: woodSmoke,
                  title: const Text(
                    'Keys',
                    style: TextStyle(
                      fontSize: FontSize.large,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(Spacing.large),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Public Key',
                            style: TextStyle(
                              fontSize: FontSize.mediumLarge,
                            ),
                          ),
                          const SizedBox(height: Spacing.medium),
                          SelectableText(
                            npubEncode,
                            style: const TextStyle(
                              fontSize: FontSize.medium,
                            ),
                          ),
                          const SizedBox(height: Spacing.mediumLarge),
                          const Text(
                            'Private Key',
                            style: TextStyle(
                              fontSize: FontSize.mediumLarge,
                            ),
                          ),
                          const SizedBox(height: Spacing.medium),
                          SelectableText(
                            nsecEncode,
                            style: const TextStyle(
                              fontSize: FontSize.medium,
                              color: flamingo,
                            ),
                          ),
                          const SizedBox(height: Spacing.mediumLarge),
                          Row(
                            children: [
                              const Spacer(),
                              Expanded(
                                child: ExpandedOutlinedButton(
                                  label: 'OK',
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
        icon: const Icon(Icons.key_outlined),
      ),
    );
  }
}

class CreateRoomCard extends StatelessWidget {
  const CreateRoomCard({
    super.key,
    required this.npubEncode,
  });

  final String npubEncode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ResponsiveBuilder(
        maxWidth: 768,
        maxHeight: 503,
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                color: athens,
                width: 2,
              ),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Room Created !',
                    style: TextStyle(
                      fontSize: FontSize.large,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: white.withOpacity(0.8),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Share your npub with your friend and ask them to join the room in order to play the game.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // SelectableText(
                  //   npubEncode,
                  // ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: npubEncode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard!'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                      ),
                      child: SelectableText(
                        npubEncode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: woodSmoke,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Currently waiting for an opponent to join the room...',
                    style: TextStyle(
                      fontSize: 16,
                      // color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ExpandedOutlinedButton(
                    onTap: () {
                      NostrJS.closeRelay();
                      Navigator.pop(context);
                    },
                    label: 'Close',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
