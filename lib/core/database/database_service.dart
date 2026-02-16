import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  static DatabaseService get instance => DatabaseService();

  /// Get database instance, copying from assets if needed
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database by copying from assets
  Future<Database> _initDatabase() async {
    final dbPath = await _getDatabasePath();
    final exists = await File(dbPath).exists();

    if (!exists) {
      // Copy database from assets
      try {
        final data = await rootBundle.load('assets/database/voters.db');
        final bytes = data.buffer.asUint8List();
        final file = File(dbPath);
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        debugPrint('Database copied from assets to: $dbPath');
      } catch (e) {
        debugPrint('Error copying database: $e');
        rethrow;
      }
    } else {
      debugPrint('Database already exists at: $dbPath');
    }

    // Open database in read-only mode without version (version requires write access)
    return await openReadOnlyDatabase(dbPath);
  }

  /// Get the path where database will be stored
  Future<String> _getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/voters.db';
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
