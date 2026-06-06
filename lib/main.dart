import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  const secureStorage = FlutterSecureStorage();
  // Inicialización de Hive con cifrado se hará por cada caja individualmente

  runApp(
    const ProviderScope(
      child: RisoApp(),
    ),
  );
}
