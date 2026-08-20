import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:eautoshop_mobile/app.dart';
import 'package:eautoshop_mobile/services/notification_service.dart';
import 'package:eautoshop_mobile/services/signalr_notifications_service.dart';
import 'package:eautoshop_mobile/providers/auth_provider.dart';
import 'package:eautoshop_mobile/providers/city_provider.dart';
import 'package:eautoshop_mobile/providers/user_provider.dart';
import 'package:eautoshop_mobile/providers/product_provider.dart';
import 'package:eautoshop_mobile/providers/product_category_provider.dart';
import 'package:eautoshop_mobile/providers/product_recommender_provider.dart';
import 'package:eautoshop_mobile/providers/car_models_by_manufacturer_provider.dart';
import 'package:eautoshop_mobile/providers/order_provider.dart';
import 'package:eautoshop_mobile/providers/order_item_provider.dart';
import 'package:eautoshop_mobile/providers/product_review_provider.dart';
import 'package:eautoshop_mobile/providers/autoshop_service_provider.dart';
import 'package:eautoshop_mobile/providers/appointment_provider.dart';
import 'package:eautoshop_mobile/providers/appointment_detail_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String stripePublishableKey = const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  if (stripePublishableKey.isEmpty) {
    try {
      await dotenv.load(fileName: '.env');

      stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    } on FileNotFoundError {
      debugPrint('Nije pronađen .env fajl.');
    }
  }

  if (stripePublishableKey.isEmpty) {
    throw Exception(
      'Nedostaje STRIPE_PUBLISHABLE_KEY. '
      'Dodaj ga u .env ili proslijedi pomoću --dart-define.',
    );
  }

  Stripe.publishableKey = stripePublishableKey;
  await Stripe.instance.applySettings();

  final notificationService = NotificationService();

  await notificationService.init();
  await notificationService.requestPermission();

  final signalRNotificationsService = SignalRNotificationsService(
    notificationService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(signalRNotificationsService),
        ),
        ChangeNotifierProvider(create: (_) => CityProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ProductCategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductRecommenderProvider()),
        ChangeNotifierProvider(
          create: (_) => CarModelsByManufacturerProvider(),
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => OrderItemProvider()),
        ChangeNotifierProvider(create: (_) => ProductReviewProvider()),
        ChangeNotifierProvider(create: (_) => AutoShopServiceProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentDetailProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
