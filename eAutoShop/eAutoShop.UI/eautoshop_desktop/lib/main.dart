import 'package:eautoshop_desktop/app.dart';
import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/providers/auth_provider.dart';
import 'package:eautoshop_desktop/providers/user_provider.dart';
import 'package:eautoshop_desktop/providers/city_provider.dart';
import 'package:eautoshop_desktop/providers/car_models_by_manufacturer_provider.dart';
import 'package:eautoshop_desktop/providers/product_category_provider.dart';
import 'package:eautoshop_desktop/providers/product_provider.dart';
import 'package:eautoshop_desktop/providers/order_item_provider.dart';
import 'package:eautoshop_desktop/providers/order_provider.dart';
import 'package:eautoshop_desktop/providers/service_type_provider.dart';
import 'package:eautoshop_desktop/providers/auto_shop_service_provider.dart';
import 'package:eautoshop_desktop/providers/appointment_detail_provider.dart';
import 'package:eautoshop_desktop/providers/appointment_provider.dart';
import 'package:eautoshop_desktop/providers/product_review_provider.dart';
import 'package:eautoshop_desktop/providers/staff_review_provider.dart';
import 'package:eautoshop_desktop/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(1100, 700),
    center: true,
    title: AppConstants.appName,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CityProvider()),
        ChangeNotifierProvider(
          create: (_) => CarModelsByManufacturerProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ProductCategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderItemProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ServiceTypeProvider()),
        ChangeNotifierProvider(create: (_) => AutoShopServiceProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentDetailProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => ProductReviewProvider()),
        ChangeNotifierProvider(create: (_) => StaffReviewProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
