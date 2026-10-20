import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/ar_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ganti dengan URL dan Anon Key dari dashboard Supabase kamu
  await Supabase.initialize(
    url: 'https://judwcvarmihgcxagwama.supabase.co',
    anonKey: 'sb_publishable_IaNyIki6oPVsHGwKytEYJg_hoD1cxfT',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Face Tracking',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ARScreen(),
    );
  }
}