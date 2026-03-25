import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/shared/services/analytics/app_error_reporter.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';
import 'package:organiq/shared/services/push/firebase_bootstrap.dart';

import 'presentation/app.dart';
import 'presentation/routes/app_module.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final monitoring = AppMonitoringService.instance;

      FlutterError.onError = (details) {
        final detailsContext = details.context;
        FlutterError.presentError(details);
        AppErrorReporter.report(
          AppErrorReportPayload(
            source: 'flutter',
            errorCode: 'flutter_error',
            message: details.exceptionAsString(),
            stackTrace: details.stack?.toString(),
            metadata: <String, dynamic>{
              if (details.library != null) 'library': details.library,
              if (detailsContext != null)
                'context': detailsContext.toDescription(),
            },
          ),
        );

        unawaited(monitoring.recordFlutterFatalError(details));
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        AppErrorReporter.report(
          AppErrorReportPayload(
            source: 'flutter',
            errorCode: 'platform_error',
            message: error.toString(),
            stackTrace: stackTrace.toString(),
          ),
        );
        unawaited(
          monitoring.recordError(
            error,
            stackTrace,
            reason: 'platform_dispatcher_uncaught',
            fatal: true,
          ),
        );
        return true;
      };

      try {
        await FirebaseBootstrap.initialize();
      } catch (error, stackTrace) {
        AppErrorReporter.report(
          AppErrorReportPayload(
            source: 'bootstrap',
            errorCode: 'firebase_bootstrap',
            message: error.toString(),
            stackTrace: stackTrace.toString(),
          ),
        );
        unawaited(
          monitoring.recordError(
            error,
            stackTrace,
            reason: 'firebase_bootstrap_initialize_failed',
          ),
        );
      }

      runApp(ModularApp(module: AppModule(), child: const AppWidget()));
    },
    (error, stackTrace) {
      final monitoring = AppMonitoringService.instance;
      AppErrorReporter.report(
        AppErrorReportPayload(
          source: 'flutter',
          errorCode: 'uncaught_zone_error',
          message: error.toString(),
          stackTrace: stackTrace.toString(),
        ),
      );
      unawaited(
        monitoring.recordError(
          error,
          stackTrace,
          reason: 'run_zoned_guarded_uncaught',
          fatal: true,
        ),
      );
    },
  );
}
