import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrawars/component_library/component_library.dart';
import 'package:nostrawars/features/create_room/create_room.dart';
import 'package:nostrawars/features/join_room/src/join_room_screen.dart';
import 'package:nostrawars/lnbits_api/lnbits_api.dart';

class PayInvoiceScreen extends StatefulWidget {
  const PayInvoiceScreen({
    super.key,
    required this.action,
  });
  final String action;

  @override
  State<PayInvoiceScreen> createState() => _PayInvoiceScreenState();
}

class _PayInvoiceScreenState extends State<PayInvoiceScreen> {
  Future<InvoiceRM>? _futureInvoice;

  String? paymentHash;

  FutureBuilder<InvoiceRM> buildInvoiceQR() {
    return FutureBuilder<InvoiceRM>(
      future: _futureInvoice,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          paymentHash = snapshot.data?.paymentHash;
          return Column(
            children: [
              QrCard(
                qrData: snapshot.data!.paymentRequest,
              ),
              const SizedBox(height: Spacing.xLarge),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: snapshot.data!.paymentHash,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invoice copied to clipboard!'),
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
                    snapshot.data!.paymentRequest,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: FontSize.medium,
                      fontWeight: FontWeight.bold,
                      color: woodSmoke,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xLarge),
              Text(
                'To ${widget.action.toLowerCase()}, you must make a payment of 10 sats into the system through the above invoice. However, here\'s an exciting twist - if you win the game, you\'ll receive double the amount, that is, 20 sats.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: FontSize.medium,
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          print('[!] snapshot hasError: ${snapshot.error}');
          return const Icon(Icons.error);
        }

        return const CircularProgressIndicator();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    print('[+] initState()');
    _futureInvoice = LNBitsApi.createInvoice(
      amount: 10,
      memo: widget.action,
      unit: 'sat',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameCursor(
      child: Scaffold(
        body: Stack(
          children: [
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
              child: Center(
                child: ResponsiveBuilder(
                  maxWidth: 768,
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
                        children: [
                          SizedBox(
                            width: 768,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.qr_code),
                                Text(
                                  'Pay Invoice to ${widget.action}',
                                  style: TextStyle(
                                    fontSize: FontSize.mediumLarge,
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
                                const SizedBox(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          buildInvoiceQR()
                        ],
                      ),
                    ),
                  )),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: SizedBox(
                width: 250,
                child: ExpandedOutlinedButton(
                  label: 'Check Invoice Paid ?',
                  onTap: () async {
                    if (paymentHash != null) {
                      final invoiceStatus =
                          await LNBitsApi.checkInvoiceStatus(paymentHash!);

                      navigateToRoomScreen(invoiceStatus.paid);
                    }
                  },
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: SizedBox(
                width: 210,
                child: ExpandedElevatedButton(
                  label: 'Back to main',
                  onTap: () async {
                    Navigator.pop(context);
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void navigateToRoomScreen(bool invoiceStatus) {
    if (invoiceStatus) {
      if (widget.action == 'Create Room') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateRoomScreen(),
          ),
        );
      } else if (widget.action == 'Join Room') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const JoinRoomScreen(),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          GenericErrorSnackBar(message: 'Invoice is not paid !'),
        );
    }
  }
}
