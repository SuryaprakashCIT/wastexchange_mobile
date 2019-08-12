import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:wastexchange_mobile/screens/home_screen.dart';

Future main() async {
  await DotEnv().load('.env');
  // Access the environment variables from the .env using DotEnv().env['MAPS_API_KEY'];

  Logger.level = Level.verbose;

  runApp(HomeScreen());
}
