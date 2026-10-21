import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  debugPrint('Supabase connection is ready');

  await _ensureSession();

  runApp(const MyApp());
}

Future<void> _ensureSession() async {
  final auth = Supabase.instance.client.auth;

  if (auth.currentSession != null) {
    debugPrint('There is already a session: ${auth.currentUser?.id}');
    return;
  }

  try {
    await auth.signInAnonymously();
    debugPrint('Signed in anonymously: ${auth.currentUser?.id}');
  } catch (e) {
    debugPrint('Unable to sign in anonymously: $e');
  }
}