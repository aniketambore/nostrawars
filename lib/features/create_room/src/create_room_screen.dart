// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';
import 'package:nostrawars/features/game/game.dart';
import 'package:nostrawars/features/main_page/main_page.dart';
import 'package:nostrawars/component_library/component_library.dart';
import 'package:nostrawars/nostr/nostr.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  // var relay = NostrTools.relayInit('wss://relay.damus.io');
  final _relayUrl = 'wss://nos.lol';
  final keys = Keys();
  late WebSocketChannel _relay;
  late Nip04 _nip04;
  var sk1 = '';
  var pk1 = '';
  bool connected = false;

  bool syn = false;
  bool synAck = false;
  bool ack = false;

  String synAckSha = '';

  bool gameStarted = false;
  late final MyGame _game;
  String opponentPlayer = '';

  Future<void> _closeRelay() async {
    print('[+] main.dart | _ChatScreenState | _closeRelay()');

    await _relay.sink.close();
    setState(() {
      connected = false;
    });
  }

  final Completer<void> _connectCompleter = Completer<void>();

  Future<void> startGame(String gameText) async {
    print('gameText: $gameText');
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
      }
    }
  }

  Future<void> _initializeGame() async {
    _game = MyGame(onGameStateUpdate: (position, health) async {
      // Loop until the send succeeds if the payload is to notify defeat.
      do {
        await sendDm(
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
      // relay.close();
      print('[!] Line:93 | _closeRelay triggered');
      _closeRelay();
      setState(() {
        gameStarted = false;
      });
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: ((context) {
          return AlertDialog(
            title: Text(playerWon ? 'You Won!' : 'You lost...'),
            actions: [
              TextButton(
                onPressed: () async {
                  // relay.close();
                  print('[!] Line:108 | _closeRelay triggered');
                  _closeRelay();
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MainPageScreen(),
                    ),
                  );
                },
                child: const Text('Back to Lobby'),
              ),
            ],
          );
        }),
      );
    });
    // await for a frame so that the widget mounts
    await Future.delayed(Duration.zero);
  }

  @override
  void initState() {
    print('[+] [initState() | create_room_screen.dart]');
    super.initState();
    _generateKeys();
    if (mounted) {
      _connectRelays();
    }
    _initializeGame();
  }

  // void _generateKeys() {
  //   print('[+] [_generateKeys() | create_room_screen.dart]');
  //   sk1 = generatePrivateKey();
  //   pk1 = getPublicKey(sk1);
  //   print("privKey: $sk1\npubkey: $pk1");
  // }

  void _generateKeys() {
    print('[+] [_generateKeys() | create_room_screen.dart]');
    sk1 = 'f03b226e0c1dfde7b427971810e3bc366cd6cfbd0d3d822a26b817fcb8ae12e2';
    pk1 = 'b136202de82fb8f21129f3a5a4a3cf96b6d84dc243e80d8dd7c103e5649e1bcb';
    print("privKey: $sk1\npubkey: $pk1");
  }

  Future<void> _retryConnect() async {
    print('[+] [_retryConnect() | create_room_screen.dart]');
    await Future.delayed(const Duration(seconds: 10));
    _connectRelays();
  }

  void _connectRelays() async {
    _nip04 = Nip04(sk1);

    print('[+] [main.dart | _ChatScreenState | _connectRelays()]');
    final subscriptionId = generate64RandomHexChars();

    _relay = WebSocketChannel.connect(
      // Uri.parse('wss://relay.damus.io'), // or any nostr relay
      Uri.parse(_relayUrl), // or any nostr relay
    );

    final filter = Request(subscriptionId, [
      Filter(
        kinds: [4],
        p: [pk1],
        since: currentUnixTimestampSeconds(),
      ),
    ]);

    _relay.sink.add(filter.serialize());

    _relay.stream.listen(
      (payload) async {
        print(
          '[+] [main.dart | _ChatScreenState | _connectRelays()] | Received event: $payload',
        );
        final message = Message.deserialize(payload);

        // if (message.type == 'OK') {
        //   print('[+] [main.dart | __connectRelays() | _sendEvent() response]');
        //   setState(() {
        //     _msgList.add(messageController.text.trim());
        //     messageController.clear();
        //   });
        // }

        if (message.type != "EVENT") {
          return;
        }

        final event = message.message as Event;
        print(
          '[+] [main.dart | _ChatScreenState | _connectRelays()] | Received event from: ${event.pubkey}',
        );

        try {
          final plaintext = await _nip04.decryptContent(event);

          print('[+] plaintext: $plaintext');

          if (plaintext.isNotEmpty) {
            print('[+] Plaintext is $plaintext');
            print('[+] gameStarted: $gameStarted');
            if (gameStarted) {
              // print('[+] plainText: $plaintext');
              // setState(() => opponentPlayer = event.pubkey);
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
              sendDm(messageToSend, event.pubkey);
            } else if (parsedList.first == "ACK" &&
                parsedList.last == synAckSha &&
                syn &&
                synAck) {
              print(
                '[+] [_decrypt() | create_room_screen.dart]: ACK: ${parsedList.last}',
              );
              setState(() {
                ack = true;
                gameStarted = true;
                opponentPlayer = event.pubkey;
              });

              // await a frame to allow subscribing to a new channel in a realtime callback
              await Future.delayed(Duration.zero);
              setState(() {});
              _game.startNewGame();
              print('[+] Push to game screen');
            }
          }
        } catch (e) {
          print(
            '[!] [main.dart | _ChatScreenState | _connectRelays()] : [Catch: $e]',
          );
          setState(() => connected = false);
          _closeRelay();
          _retryConnect();
        }
      },
      onError: (error) {
        print(
            '[!] [main.dart | _ChatScreenState | _connectRelays()] | Error: $error');
        print('[!] Line:317 | _closeRelay triggered');

        setState(() => connected = false);
        _closeRelay();
        _retryConnect();
      },
      cancelOnError: true,
    );

    _connectCompleter.complete();

    setState(() {
      connected = true;
    });
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

  Widget gameOn() {
    return ElevatedButton(
        onPressed: () {
          sendDm(
            '{"x":45.00,"y":8.23,"health":10}',
            opponentPlayer,
          );
        },
        child: const Text('Game ON'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    npubEncode: npubEncode,
                    relay: _relay,
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
                (pk1.isNotEmpty && sk1.isNotEmpty && !gameStarted)
                    ? ShowKeys(npubEncode: npubEncode, nsecEncode: nsecEncode)
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
    );
  }

  String get npubEncode => keys.npubEncode(pk1);

  String get nsecEncode => keys.nsecEncode(sk1);

  Future<void> sendDm(String message, String receiver) async {
    if (connected) {
      final start = DateTime.now();

      if (message.trim().isEmpty) return;

      final pk2 = receiver;
      print('[+] Sending to pubkey: $pk2');

      final ciphertext = _nip04.encrypt(pk2, message);
      print('[+] ciphertext: $ciphertext');

      // Event event = Event.from(
      //   kind: 4,
      //   tags: [
      //     ['p', pk2]
      //   ],
      //   content: ciphertext,
      //   privkey: sk1,
      //   createdAt: currentUnixTimestampSeconds(),
      // );

      Event event = Event.partial(
        kind: 4,
        tags: [
          ['p', pk2]
        ],
        content: ciphertext,
        pubkey: pk1,
        createdAt: currentUnixTimestampSeconds(),
      );

      event.id = event.getEventId();
      event.sig = event.getSignature(sk1);

      var end = DateTime.now();
      var time = end.difference(start);
      print('[!] Got the event now $time!');

      await _sendEvent(event, message);
    }
  }

  Future<void> _sendEvent(Event event, String message) async {
    try {
      _relay.sink.add(event.serialize());

      _onPublishSuccess(message);
    } catch (e) {
      print(
        '[!] [create_room_screen.dart | _CreateRoomScreenState | _sendEvent()]',
      );
    }
  }

  void _onPublishSuccess(String message) {
    print('[+] _onPublishSuccess | relay has accepted our event');
    if (!synAck) {
      List<String> parsedList = parseText(message);
      if (parsedList.first == 'SYN-ACK') {
        setState(() {
          synAck = true;
          synAckSha = parsedList.last;
        });
      }
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
    required this.relay,
  });

  final String npubEncode;
  final WebSocketChannel relay;

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
                    'Share your npub with your friend and ask them to join the room in order to play the game!',
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    npubEncode,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Currently waiting for an opponent to join the room...',
                  ),
                  const SizedBox(height: 16),
                  ExpandedOutlinedButton(
                    onTap: () {
                      relay.sink.close();
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
