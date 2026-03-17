import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/shared/services/push/firebase_bootstrap.dart';

import 'presentation/app.dart';
import 'presentation/routes/app_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseBootstrap.initialize();
  } catch (error, stackTrace) {
    print('Firebase bootstrap error: $error');
    print('Firebase bootstrap stack trace: $stackTrace');
  }

  final currentZone = Zone.current;

  runZonedGuarded(
    () => currentZone.run(() {
      runApp(ModularApp(module: AppModule(), child: const AppWidget()));
    }),
    (error, stackTrace) {
      // Handle uncaught errors here
      print('Uncaught error: $error');
      print('Stack trace: $stackTrace');
    },
  );
}
