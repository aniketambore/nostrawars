// Define the library and import the JS interop library
@JS()
library nostr;

import 'package:js/js.dart';

// Define the JS interop class
// @JS()
// class NostrTools {
//   // Define external static methods for generating a private key, getting a public key, initializing a relay, getting an event hash, and signing an event
//   external static dynamic generatePrivateKey(String passphrase);
//   external static dynamic getPublicKey(String passphrase);
//   external static dynamic relayInit(String relay);
//   external static dynamic getEventHash(Event event);
//   external static dynamic signEvent(Event event, String privateKey);

//   // Define external static properties for getting nip05, nip19, and nip04
//   external static get nip05;
//   external static get nip19;
//   external static get nip04;
// }

// // Define an anonymous JS interop class for an event
// @JS()
// @anonymous
// class Event {
//   // Define external getters and setters for the kind, created_at, tags, content, pubkey, id, and sig properties of an event
//   external int get kind;
//   external set kind(int value);

//   external int get created_at;
//   external set created_at(int value);

//   external List<String> get tags;
//   external set tags(List<String> value);

//   external String get content;
//   external set content(String value);

//   external String get pubkey;
//   external set pubkey(String value);

//   external String get id;
//   external set id(String value);

//   external String get sig;
//   external set sig(String value);

//   // Define a factory constructor for an event that takes in the kind, created_at, tags, content, pubkey, id, and sig properties
//   external factory Event({
//     int kind,
//     int created_at,
//     List<dynamic> tags,
//     String content,
//     String pubkey,
//     String id,
//     String sig,
//   });
// }

// @JS("JSON.stringify")
// external String stringify(Object obj);

@JS()
external Future<bool> connectToRelay(
    void Function() connectedCallback,
    String sk1,
    String pk1,
    void Function(String, String) eventReceivedCallback);

@JS()
external Future<bool> sendDm(message, senderSk, senderPk, receiverPk,
    void Function(String) onPublishSuccessCallback);

@JS()
external String nsecEncode(sk);

@JS()
external String npubEncode(pk);

@JS()
external void closeRelay();
