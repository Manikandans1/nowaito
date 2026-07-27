import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'services/api_service.dart';
import 'services/session_provider.dart';
import 'services/notification_service.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  ApiService.instance.init();
  await NotificationService.instance.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => SessionProvider()..load(),
      child: const NoWaitoApp(),
    ),
  );
}

class NoWaitoApp extends StatefulWidget {
  const NoWaitoApp({super.key});
  @override
  State<NoWaitoApp> createState() => _NoWaitoAppState();
}

class _NoWaitoAppState extends State<NoWaitoApp> {
  late final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NoWaito',
      debugShowCheckedModeBanner: false,
      theme: nowaitoTheme(),
      routerConfig: _router,
    );
  }
}
