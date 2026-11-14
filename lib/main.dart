import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'app/url_strategy.dart';

Future<void> main() async {
  configureWebUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.bootstrap();
  runApp(MeuPrecoApp(dependencies: dependencies));
}
