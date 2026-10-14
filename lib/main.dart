import 'package:flutter/material.dart';
import 'providers/delivery_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await LocalStorageService.init();
  final provider = DeliveryProvider(storage);
  runApp(NewspaperDeliveryApp(provider: provider));
}

class NewspaperDeliveryApp extends StatelessWidget {
  final DeliveryProvider provider;

  const NewspaperDeliveryApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return MaterialApp(
          title: provider.strings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
            ),
            cardTheme: CardThemeData(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          home: provider.isLoggedIn
              ? HomeScreen(provider: provider)
              : LoginScreen(provider: provider),
        );
      },
    );
  }
}

