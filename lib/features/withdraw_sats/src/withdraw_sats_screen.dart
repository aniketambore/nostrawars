import 'package:flutter/material.dart';
import 'package:nostrawars/component_library/component_library.dart';
import 'package:nostrawars/features/main_page/src/main_page_screen.dart';
import 'package:nostrawars/lnbits_api/lnbits_api.dart';

class WithdrawSatsScreen extends StatefulWidget {
  const WithdrawSatsScreen({
    super.key,
    required this.winnerNpub,
  });
  final String winnerNpub;

  @override
  State<WithdrawSatsScreen> createState() => _WithdrawSatsScreenState();
}

class _WithdrawSatsScreenState extends State<WithdrawSatsScreen> {
  Future<WithdrawLinkRM>? _futureWithdrawLink;

  FutureBuilder<WithdrawLinkRM> buildWithdrawLinkQr() {
    return FutureBuilder<WithdrawLinkRM>(
      future: _futureWithdrawLink,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              QrCard(qrData: snapshot.data!.lnurl),
              const SizedBox(height: 20),
              const Text(
                'Scan the QR code above to claim your prize!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: flamingo,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'If you fail to claim your prize using the LNURL withdraw invoice provided above, your sats will be considered a contribution to nostrawars. Thank you for participating!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: flamingo,
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return const Icon(Icons.error);
        }

        return const CircularProgressIndicator();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _futureWithdrawLink = LNBitsApi.createWithdrawLink(
      title: widget.winnerNpub,
      minWithdrawable: 10,
      maxWithdrawable: 20,
      uses: 1,
      waitTime: 10,
      isUnique: true,
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
                            Text(
                              'Winner winner, sats for dinner!',
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
                            buildWithdrawLinkQr(),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainPageScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
