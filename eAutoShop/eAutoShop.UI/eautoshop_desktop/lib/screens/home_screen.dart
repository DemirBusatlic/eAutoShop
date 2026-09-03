import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenModule});

  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final modules = _modulesFor(auth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dobro došli, ${auth.currentUsername ?? 'korisniče'}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            'Prijavljeni ste kao: ${_roleLabel(auth.currentRole)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppPadding.large),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 4
                  : constraints.maxWidth >= 760
                  ? 3
                  : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: modules.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppPadding.medium,
                  mainAxisSpacing: AppPadding.medium,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, index) {
                  final module = modules[index];

                  return _DashboardCard(
                    title: module.title,
                    description: module.description,
                    icon: module.icon,
                    onPressed: () => onOpenModule(module.key),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<_HomeModule> _modulesFor(AuthProvider auth) {
    return [
      if (!auth.isTechnician)
        const _HomeModule(
          key: 'products',
          title: 'Proizvodi',
          description: 'Pregled i upravljanje ponudom proizvoda.',
          icon: Icons.inventory_2_outlined,
        ),
      const _HomeModule(
        key: 'services',
        title: 'Usluge',
        description: 'Pregled i upravljanje uslugama auto shopa.',
        icon: Icons.build_outlined,
      ),
      const _HomeModule(
        key: 'orders',
        title: 'Narudžbe',
        description: 'Obrada i praćenje narudžbi kupaca.',
        icon: Icons.receipt_long_outlined,
      ),
      if (auth.isManager || auth.isTechnician)
        const _HomeModule(
          key: 'appointments',
          title: 'Rezervacije',
          description: 'Pregled i obrada zakazanih termina.',
          icon: Icons.calendar_month_outlined,
        ),
      if (auth.isManager) ...[
        const _HomeModule(
          key: 'customers',
          title: 'Korisnici',
          description: 'Upravljanje korisničkim nalozima.',
          icon: Icons.people_outline,
        ),
        const _HomeModule(
          key: 'employees',
          title: 'Zaposlenici',
          description: 'Upravljanje nalozima zaposlenika.',
          icon: Icons.badge_outlined,
        ),
      ],
      if (!auth.isTechnician)
        const _HomeModule(
          key: 'reviews',
          title: 'Recenzije',
          description: 'Pregled recenzija proizvoda i zaposlenika.',
          icon: Icons.reviews_outlined,
        ),
      const _HomeModule(
        key: 'reports',
        title: 'Izvještaji',
        description: 'Generisanje i pregled poslovnih izvještaja.',
        icon: Icons.bar_chart_outlined,
      ),
    ];
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'manager':
        return 'menadžer';
      case 'salesperson':
        return 'prodajno osoblje';
      case 'technician':
        return 'tehničar';
      default:
        return 'zaposlenik';
    }
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 34, color: colorScheme.primary),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppPadding.small),
              Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeModule {
  const _HomeModule({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String key;
  final String title;
  final String description;
  final IconData icon;
}
