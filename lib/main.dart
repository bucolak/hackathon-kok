import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, this.connect});

  final Future<void> Function()? connect;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _initialized = false;
  late Future<void> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _connect();
  }

  Future<void> _connect() async {
    if (widget.connect case final connect?) {
      await connect();
      return;
    }
    if (!_initialized) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
      _initialized = true;
    }
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      await auth.signInAnonymously();
    }
    if (auth.currentSession == null) {
      throw StateError('Oturum oluşturulamadı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const MyApp();
        }
        return MaterialApp(
          title: 'Köke Yolculuk',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child:
                      snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Bağlantı kurulamadı veya misafir oturumu açılamadı. '
                              'İnternet bağlantınızı kontrol edip tekrar deneyin.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  _startup = _connect();
                                });
                              },
                              child: const Text('Tekrar dene'),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Bağlantı kuruluyor…'),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
