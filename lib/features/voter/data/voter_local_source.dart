import 'package:flutter/foundation.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/utils/digit_converter.dart';

class VoterLocalSource {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Search voters from local database
  Future<Map<String, dynamic>> search(Map<String, dynamic> payload) async {
    final db = await _dbService.database;
    final searchType = payload['search_type'] as String;
    final searchValue = payload['search_value'] as String? ?? '';
    final dobDay = payload['dob_day'] as String? ?? '';
    final dobMonth = payload['dob_month'] as String? ?? '';
    final dobYear = payload['dob_year'] as String? ?? '';

    List<Map<String, dynamic>> results = [];

    try {
      // Build WHERE clause based on search type
      String whereClause = '';
      List<dynamic> whereArgs = [];

      switch (searchType) {
        case 'voter_id':
          whereClause = 'voter_no LIKE ?';
          whereArgs.add('%${searchValue.trim()}%');
          break;

        case 'name':
          // Trim and ensure search value is not empty
          final trimmedName = searchValue.trim();
          if (trimmedName.isEmpty) {
            whereClause = '1=0'; // Return no results if empty
          } else {
            // Search in name column with trimmed value
            whereClause = 'name LIKE ?';
            whereArgs.add('%$trimmedName%');
            debugPrint('Name search: name LIKE %$trimmedName%');
          }
          break;

        case 'fathers_name':
          final trimmedFatherName = searchValue.trim();
          if (trimmedFatherName.isEmpty) {
            whereClause = '1=0';
          } else {
            whereClause = 'fathers_name LIKE ?';
            whereArgs.add('%$trimmedFatherName%');
            debugPrint('Father name search: fathers_name LIKE %$trimmedFatherName%');
          }
          break;

        case 'mothers_name':
          final trimmedMotherName = searchValue.trim();
          if (trimmedMotherName.isEmpty) {
            whereClause = '1=0';
          } else {
            whereClause = 'mothers_name LIKE ?';
            whereArgs.add('%$trimmedMotherName%');
            debugPrint('Mother name search: mothers_name LIKE %$trimmedMotherName%');
          }
          break;

        case 'area':
          // Build area search with ward and area conditions
          List<String> conditions = [];

          // If স্থানীয় প্রশাসন (local_administrative_area) is selected, check union_name and ward_no
          if (payload['local_administrative_area'] != null) {
            final localArea = payload['local_administrative_area'].toString();
            if (localArea.isNotEmpty) {
              // Extract ward number from "ওয়ার্ড নং-৬৩" format
              String? wardNumber;

              // Pattern: "ওয়ার্ড নং-৬৩" or "ওয়ার্ড নং-৬৩ (পার্ট)" etc.
              final wardMatch = RegExp(r'[০-৯]+').firstMatch(localArea);
              if (wardMatch != null) {
                wardNumber = wardMatch.group(0);
              }

              // Search in multiple ways for better matching
              List<String> wardConditions = [];

              // 1. Search in union_name with full text
              wardConditions.add('union_name LIKE ?');
              whereArgs.add('%$localArea%');

              // 2. Search in union_name with just the ward number
              if (wardNumber != null) {
                wardConditions.add('union_name LIKE ?');
                whereArgs.add('%$wardNumber%');
              }

              // 3. Search in ward_no column (if it exists and matches)
              if (wardNumber != null) {
                // Convert Bengali digits to English for ward_no comparison
                final wardNoEn = DigitConverter.bnToEn(wardNumber);
                wardConditions.add('(ward_no = ? OR ward_no LIKE ?)');
                whereArgs.add(wardNoEn);
                whereArgs.add('%$wardNumber%');
              }

              // Combine all ward conditions with OR
              if (wardConditions.isNotEmpty) {
                conditions.add('(${wardConditions.join(' OR ')})');
                debugPrint('Area search: Ward search with multiple patterns');
                debugPrint('  - Full text: $localArea');
                debugPrint('  - Ward number: $wardNumber');
              }
            }
          }

          // If এলাকা (selectedArea) is selected, check vote_area_name
          if (payload['selected_area'] != null) {
            final areaName = payload['selected_area'].toString().trim();
            if (areaName.isNotEmpty) {
              // Search with exact match and also with trimmed/cleaned version
              conditions.add('vote_area_name LIKE ?');
              whereArgs.add('%$areaName%');
              debugPrint('Area search: vote_area_name LIKE %$areaName%');
            }
          } else if (payload['area_id'] != null) {
            // Or match by vote_area_no if ID is provided
            conditions.add('vote_area_no = ?');
            whereArgs.add(payload['area_id']);
            debugPrint('Area search: vote_area_no = ${payload['area_id']}');
          }

          // Add gender filter if provided (gender is already in English lowercase from presenter)
          if (payload['gender'] != null) {
            final genderValue = payload['gender']
                .toString()
                .trim()
                .toLowerCase();
            if (genderValue.isNotEmpty) {
              // Database has gender in lowercase (male/female)
              // Match both full and abbreviated forms
              if (genderValue == 'male' || genderValue == 'm') {
                conditions.add("(gender = 'male' OR gender = 'm')");
              } else if (genderValue == 'female' || genderValue == 'f') {
                conditions.add("(gender = 'female' OR gender = 'f')");
              } else {
                // Fallback: direct match
                conditions.add('gender LIKE ?');
                whereArgs.add('%$genderValue%');
              }

              debugPrint('Area search: Gender filter = $genderValue');
            }
          }

          // If no conditions, return empty (shouldn't happen, but safety check)
          if (conditions.isEmpty) {
            debugPrint('Area search: No conditions found, returning empty');
            whereClause = '1=0'; // Return no results
          } else {
            whereClause = conditions.join(' AND ');
            debugPrint('Area search WHERE clause: $whereClause');
            debugPrint('Area search WHERE args: $whereArgs');
          }
          break;

        case 'address':
          // Build address search with multiple conditions
          List<String> conditions = [];

          // If address text is provided, check address column
          if (searchValue.isNotEmpty && searchValue.trim().isNotEmpty) {
            conditions.add('address LIKE ?');
            whereArgs.add('%$searchValue%');
            debugPrint('Address search: address LIKE %$searchValue%');
          }

          // If স্থানীয় প্রশাসন (local_administrative_area) is selected, check union_name and ward_no
          if (payload['local_administrative_area'] != null) {
            final localArea = payload['local_administrative_area'].toString();
            if (localArea.isNotEmpty) {
              // Extract ward number from "ওয়ার্ড নং-৬৩" format
              // Try to extract the number part (e.g., "৬৩" from "ওয়ার্ড নং-৬৩")
              String? wardNumber;

              // Pattern: "ওয়ার্ড নং-৬৩" or "ওয়ার্ড নং-৬৩ (পার্ট)" etc.
              final wardMatch = RegExp(r'[০-৯]+').firstMatch(localArea);
              if (wardMatch != null) {
                wardNumber = wardMatch.group(0);
              }

              // Search in multiple ways for better matching
              List<String> wardConditions = [];

              // 1. Search in union_name with full text
              wardConditions.add('union_name LIKE ?');
              whereArgs.add('%$localArea%');

              // 2. Search in union_name with just the ward number
              if (wardNumber != null) {
                wardConditions.add('union_name LIKE ?');
                whereArgs.add('%$wardNumber%');
              }

              // 3. Search in ward_no column (if it exists and matches)
              if (wardNumber != null) {
                // Convert Bengali digits to English for ward_no comparison
                final wardNoEn = DigitConverter.bnToEn(wardNumber);
                wardConditions.add('(ward_no = ? OR ward_no LIKE ?)');
                whereArgs.add(wardNoEn);
                whereArgs.add('%$wardNumber%');
              }

              // Combine all ward conditions with OR
              if (wardConditions.isNotEmpty) {
                conditions.add('(${wardConditions.join(' OR ')})');
                debugPrint(
                  'Address search: Ward search with multiple patterns',
                );
                debugPrint('  - Full text: $localArea');
                debugPrint('  - Ward number: $wardNumber');
              }
            }
          }

          // If এলাকা (selectedArea) is selected, check vote_area_name
          if (payload['selected_area'] != null) {
            final areaName = payload['selected_area'].toString().trim();
            if (areaName.isNotEmpty) {
              // Search with exact match and also with trimmed/cleaned version
              conditions.add('vote_area_name LIKE ?');
              whereArgs.add('%$areaName%');
              debugPrint('Address search: vote_area_name LIKE %$areaName%');
            }
          } else if (payload['area_id'] != null) {
            // Or match by vote_area_no if ID is provided
            conditions.add('vote_area_no = ?');
            whereArgs.add(payload['area_id']);
            debugPrint('Address search: vote_area_no = ${payload['area_id']}');
          }

          // Add gender filter if provided (gender is already in English lowercase from presenter)
          if (payload['gender'] != null) {
            final genderValue = payload['gender']
                .toString()
                .trim()
                .toLowerCase();
            if (genderValue.isNotEmpty) {
              // Database has gender in lowercase (male/female)
              // Match both full and abbreviated forms
              if (genderValue == 'male' || genderValue == 'm') {
                conditions.add("(gender = 'male' OR gender = 'm')");
              } else if (genderValue == 'female' || genderValue == 'f') {
                conditions.add("(gender = 'female' OR gender = 'f')");
              } else {
                // Fallback: direct match
                conditions.add('gender LIKE ?');
                whereArgs.add('%$genderValue%');
              }

              debugPrint('Address search: Gender filter = $genderValue');
            }
          }

          // If no conditions, return empty (shouldn't happen, but safety check)
          if (conditions.isEmpty) {
            debugPrint('Address search: No conditions found, returning empty');
            whereClause = '1=0'; // Return no results
          } else {
            whereClause = conditions.join(' AND ');
            debugPrint('Address search WHERE clause: $whereClause');
            debugPrint('Address search WHERE args: $whereArgs');
          }
          break;

        default:
          whereClause = 'name LIKE ?';
          whereArgs.add('%$searchValue%');
      }

      // Add DOB filter if provided (for non-address and non-area searches)
      if (searchType != 'address' &&
          searchType != 'area' &&
          dobDay.isNotEmpty &&
          dobMonth.isNotEmpty &&
          dobYear.isNotEmpty) {
        // Database stores DOB as 'YYYY-MM-DD' format
        // Convert Bengali digits to English if needed
        final dayEn = DigitConverter.bnToEn(dobDay);
        final monthEn = DigitConverter.bnToEn(dobMonth);
        final yearEn = DigitConverter.bnToEn(dobYear);

        // Pad day and month with zero if needed
        final dayPadded = dayEn.length == 1 ? '0$dayEn' : dayEn;
        final monthPadded = monthEn.length == 1 ? '0$monthEn' : monthEn;

        // Database format is YYYY-MM-DD
        final dobString = '$yearEn-$monthPadded-$dayPadded';

        whereClause += ' AND dob LIKE ?';
        whereArgs.add('%$dobString%');
      }

      // Query the database with pagination
      final page = payload['page'] as int? ?? 1;
      final limit = payload['limit'] as int? ?? 500;
      final offset = (page - 1) * limit;

      debugPrint('Executing query: WHERE $whereClause');
      debugPrint('Query args: $whereArgs');
      debugPrint('Pagination: page=$page, limit=$limit, offset=$offset');

      // Get total count first (without pagination)
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as total FROM voters WHERE $whereClause',
        whereArgs,
      );
      final totalCount = countResult.first['total'] as int? ?? 0;

      debugPrint('Total count: $totalCount');

      // Get paginated results, sorted by serial number (sl) in ascending order
      results = await db.query(
        'voters',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'CAST(sl AS INTEGER) ASC', // Sort by serial number numerically
        limit: limit,
        offset: offset,
      );

      debugPrint(
        'Query returned ${results.length} results out of $totalCount total',
      );

      // Map database columns to API response format
      final mappedResults = results.map((row) {
        return {
          'id': row['id'],
          'serial': row['sl'] ?? row['id'],
          'voter_id': row['voter_no'],
          'name': row['name'],
          'fathers_name': row['fathers_name'],
          'mothers_name': row['mothers_name'],
          'dob': row['dob'],
          'date_of_birth': row['dob'],
          'gender': row['gender'],
          'address': row['address'],
          'occupation': row['occupation'],
          'area': {
            'local_administrative_area': row['union_name'],
            'vote_area_name': row['vote_area_name'],
            'vote_area_no': row['vote_area_no'],
            'ward_no': row['ward_no'],
          },
          'vote_center': {
            'name': row['center_name'],
            'center_no': row['vote_area_no'],
          },
          'union_name': row['union_name'],
          'ward_no': row['ward_no'],
          'police_station': row['police_station'],
          'post_code': row['post_code'],
          'vote_area_no': row['vote_area_no'],
          'vote_area_name': row['vote_area_name'],
          'center_name': row['center_name'],
        };
      }).toList();

      debugPrint('Mapped ${mappedResults.length} results');
      return {
        'voters': mappedResults,
        'total': totalCount,
        'current_page_count': mappedResults.length,
      };
    } catch (e, stackTrace) {
      debugPrint('Error searching database: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Search type: $searchType');
      debugPrint('Search value: $searchValue');
      debugPrint('Payload: $payload');
      rethrow;
    }
  }
}
