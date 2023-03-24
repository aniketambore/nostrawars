import 'package:flutter/material.dart';
import 'package:nostrawars/component_library/component_library.dart';
import 'package:nostrawars/features/pay_invoice/pay_invoice.dart';

class MainPageScreen extends StatefulWidget {
  const MainPageScreen({super.key});

  @override
  State<MainPageScreen> createState() => _MainPageScreenState();
}

class _MainPageScreenState extends State<MainPageScreen> {
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
              child: Center(
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
                          children: [
                            Image.asset(
                              'assets/images/player.png',
                              width: 64,
                              height: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nostrawars',
                              style: TextStyle(
                                fontSize: FontSize.large,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.white.withOpacity(0.8),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ExpandedElevatedButton(
                              label: 'Create Room',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PayInvoiceScreen(
                                      action: "Create Room",
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            ExpandedOutlinedButton(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PayInvoiceScreen(
                                      action: "Join Room",
                                    ),
                                    // builder: (context) =>
                                    //     const JoinRoomScreen(),
                                  ),
                                );
                              },
                              label: 'Join Room',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 10,
              right: 10,
              child: Text('Made for #NostHack'),
            ),
          ],
        ),
      ),
    );
  }
}
