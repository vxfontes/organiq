import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'presentation/app.dart';
import 'presentation/routes/app_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final currentZone = Zone.current;

  runZonedGuarded(() => currentZone.run(() {
        runApp(ModularApp(module: AppModule(), child: const AppWidget()));
      }), (error, stackTrace) {
    // Handle uncaught errors here
    print('Uncaught error: $error');
    print('Stack trace: $stackTrace');
  });

}
