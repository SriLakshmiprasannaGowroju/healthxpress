import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/ai_assistant_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/pharmacy_provider.dart';
import 'providers/doctor_portal_provider.dart';
import 'providers/store_provider.dart';
import 'screens/common/splash_screen.dart';

import 'data/production_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ProductionDatabase.syncWithLiveBackend();
  runApp(const HealthExpressApp());
}

class HealthExpressApp extends StatelessWidget {
  const HealthExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AiAssistantProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => PharmacyProvider()),
        ChangeNotifierProvider(create: (_) => DoctorPortalProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
      ],
      child: MaterialApp(
        title: 'HealthExpress AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
