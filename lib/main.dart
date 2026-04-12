import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/map_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'utils/user_data.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 2. Load the .env file
  await dotenv.load(fileName: ".env");

  // 🔹 3. Read the variables (using ! because we are certain they exist in the file)
  String supabaseUrl = dotenv.env['SUPABASE_URL']!;
  String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const SpotsApp(),
    ),
  );
}

class SpotsApp extends StatelessWidget {
  const SpotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}
