import 'package:eautoshop_mobile/providers/auth_provider.dart';
import 'package:eautoshop_mobile/screens/home_screen.dart';
import 'package:eautoshop_mobile/screens/login_screen.dart';
import 'package:eautoshop_mobile/screens/order_history_screen.dart';
//import 'package:eautoshop_mobile/screens/reservation_history_screen.dart';
import 'package:eautoshop_mobile/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MasterScreen extends StatelessWidget {
  final Widget child;

  const MasterScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF455A64),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: isLoggedIn
            ? Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: 'Meni',
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              )
            : null,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, size: 26),
            SizedBox(width: 8),
            Text(
              'eAutoShop',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      drawer: isLoggedIn
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 44, 41, 51),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'eAutoShop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sve za vaše vozilo',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserProfileScreen(),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 19,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Moj profil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Početna'),
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Moje narudžbe'),
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderHistoryScreen(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Moje rezervacije'),
                    onTap: () {
                      Navigator.pop(context);

                      /*Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReservationHistoryScreen(),
                        ),
                      );*/
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Odjava',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context, authProvider);
                    },
                  ),
                ],
              ),
            )
          : null,
      body: child,
    );
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Odjava'),
          content: const Text('Da li ste sigurni da se želite odjaviti?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Odustani'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Odjavi se'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    try {
      await authProvider.logout();

      if (!context.mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
