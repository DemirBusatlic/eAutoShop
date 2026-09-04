import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/providers/auth_provider.dart';
import 'package:eautoshop_desktop/screens/home_screen.dart';
import 'package:eautoshop_desktop/screens/appointment_screen.dart';
import 'package:eautoshop_desktop/screens/user_screen.dart';
import 'package:eautoshop_desktop/screens/customer_screen.dart';
import 'package:eautoshop_desktop/screens/product_screen.dart';
import 'package:eautoshop_desktop/screens/order_screen.dart';
import 'package:eautoshop_desktop/screens/service_screen.dart';
import 'package:eautoshop_desktop/screens/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  static const Color _primaryBlue = Color(0xFF2848C7);
  static const Color _contentBackground = Color(0xFFF5F7FB);

  int _selectedIndex = 0;
  bool _isMenuExpanded = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final destinations = _destinationsFor(authProvider);

    final safeIndex = _selectedIndex.clamp(0, destinations.length - 1).toInt();

    final selectedDestination = destinations[safeIndex];

    return Scaffold(
      backgroundColor: _contentBackground,
      body: Row(
        children: [
          _buildSideMenu(destinations: destinations, selectedIndex: safeIndex),
          Expanded(
            child: ColoredBox(
              color: _contentBackground,
              child: SafeArea(
                left: false,
                child: Column(
                  children: [
                    _buildTopBar(
                      context: context,
                      title: selectedDestination.label,
                      username: authProvider.currentUsername,
                      isMenuExpanded: _isMenuExpanded,
                      onMenuPressed: () {
                        setState(() {
                          _isMenuExpanded = !_isMenuExpanded;
                        });
                      },
                    ),
                    Expanded(child: selectedDestination.screen),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu({
    required List<_DesktopDestination> destinations,
    required int selectedIndex,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: _isMenuExpanded ? 250 : 76,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: _primaryBlue),
      child: SafeArea(
        child: Column(
          children: [
            _BrandHeader(isExpanded: _isMenuExpanded),
            const Divider(height: 1, color: Colors.white24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];

                  return _SideMenuItem(
                    label: destination.label,
                    icon: destination.icon,
                    isSelected: index == selectedIndex,
                    isExpanded: _isMenuExpanded,
                    onPressed: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Colors.white24),
            _SideMenuItem(
              label: 'Odjava',
              icon: Icons.logout,
              isSelected: false,
              isExpanded: _isMenuExpanded,
              onPressed: _confirmLogout,
            ),
            const SizedBox(height: AppPadding.small),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar({
    required BuildContext context,
    required String title,
    required String? username,
    required bool isMenuExpanded,
    required VoidCallback onMenuPressed,
  }) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E7F0))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: isMenuExpanded ? 'Sklopi meni' : 'Proširi meni',
            onPressed: onMenuPressed,
            icon: Icon(
              isMenuExpanded ? Icons.menu_open : Icons.menu,
              color: _primaryBlue,
            ),
          ),
          const SizedBox(width: AppPadding.small),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF1B2430),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.medium,
              vertical: AppPadding.small,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: _primaryBlue,
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                Text(
                  username ?? 'Korisnik',
                  style: const TextStyle(
                    color: Color(0xFF1B2430),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_DesktopDestination> _destinationsFor(AuthProvider authProvider) {
    return [
      _DesktopDestination(
        key: 'home',
        label: 'Početna',
        icon: Icons.dashboard_outlined,
        screen: HomeScreen(onOpenModule: _openModule),
      ),
      const _DesktopDestination(
        key: 'products',
        label: 'Proizvodi',
        icon: Icons.inventory_2_outlined,
        screen: ProductScreen(),
      ),
      const _DesktopDestination(
        key: 'services',
        label: 'Usluge',
        icon: Icons.build_outlined,
        screen: ServiceScreen(),
      ),
      if (!authProvider.isTechnician)
        const _DesktopDestination(
          key: 'orders',
          label: 'Narudžbe',
          icon: Icons.receipt_long_outlined,
          screen: OrderScreen(),
        ),
      if (authProvider.isManager || authProvider.isTechnician)
        _DesktopDestination(
          key: 'appointments',
          label: authProvider.isTechnician ? 'Zaduženja' : 'Rezervacije',
          icon: authProvider.isTechnician
              ? Icons.assignment_outlined
              : Icons.calendar_month_outlined,
          screen: const AppointmentScreen(),
        ),
      if (authProvider.isManager) ...[
        const _DesktopDestination(
          key: 'customers',
          label: 'Korisnici',
          icon: Icons.people_outline,
          screen: CustomerScreen(),
        ),
        const _DesktopDestination(
          key: 'employees',
          label: 'Zaposlenici',
          icon: Icons.badge_outlined,
          screen: UserScreen(),
        ),
      ],
      if (!authProvider.isTechnician)
        _DesktopDestination(
          key: 'reviews',
          label: 'Recenzije',
          icon: Icons.reviews_outlined,
          screen: ReviewScreen(showStaffReviews: authProvider.isManager),
        ),
      const _DesktopDestination(
        key: 'reports',
        label: 'Izvještaji',
        icon: Icons.bar_chart_outlined,
        screen: _SectionPlaceholder(title: 'Izvještaji'),
      ),
    ];
  }

  void _openModule(String key) {
    final authProvider = context.read<AuthProvider>();
    final destinations = _destinationsFor(authProvider);

    final index = destinations.indexWhere(
      (destination) => destination.key == key,
    );

    if (index >= 0) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Odjava'),
          content: const Text('Da li se želite odjaviti iz aplikacije?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Odjavi se'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}

class _SideMenuItem extends StatelessWidget {
  const _SideMenuItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isExpanded,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isExpanded ? '' : label,
      waitDuration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.small,
          vertical: 3,
        ),
        child: Material(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.field),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.field),
            hoverColor: Colors.white.withValues(alpha: 0.10),
            splashColor: Colors.white.withValues(alpha: 0.12),
            child: SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.small,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showLabel = isExpanded && constraints.maxWidth >= 120;

                    return Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 4,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(
                          width: showLabel
                              ? AppPadding.medium
                              : AppPadding.small,
                        ),
                        Icon(icon, color: Colors.white, size: 22),
                        if (showLabel) ...[
                          const SizedBox(width: AppPadding.medium),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 20,
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isExpanded});

  final bool isExpanded;

  static const Color _primaryBlue = Color(0xFF2848C7);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showTitle = isExpanded && constraints.maxWidth >= 140;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showTitle ? AppPadding.medium : 18,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.directions_car_filled, color: _primaryBlue),
                ),
                if (showTitle) ...[
                  const SizedBox(width: AppPadding.medium),
                  const Expanded(
                    child: Text(
                      AppConstants.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.extraLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 54,
                color: Color(0xFF2848C7),
              ),
              const SizedBox(height: AppPadding.medium),
              Text(
                '$title – ekran će biti dodan u narednom koraku.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1B2430),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopDestination {
  const _DesktopDestination({
    required this.key,
    required this.label,
    required this.icon,
    required this.screen,
  });

  final String key;
  final String label;
  final IconData icon;
  final Widget screen;
}
