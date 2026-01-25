import 'package:flutter/material.dart';
import 'package:loadintel/app.dart';
import 'package:loadintel/data/db/app_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LoadIntelApp(database: AppDatabase()));
}

