import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_texts.dart';
import '../../../../core/services/nid_ocr_service.dart';
import '../../../../core/utils/digit_converter.dart';
import '../../../../core/utils/validators.dart';
import '../../data/voter_history_service.dart';
import '../../data/voter_local_source.dart';
import '../ui_state/voter_ui_state.dart';

class VoterPresenter extends GetxController {
  final _state = VoterUiState().obs;
  VoterUiState get state => _state.value;

  final nameController = TextEditingController();
  final dayController = TextEditingController();
  final monthController = TextEditingController();
  final yearController = TextEditingController();

  /// Current search type label (e.g., "নাম", "ভোটার আইডি নম্বর")
  final RxString searchType = AppTexts.name.obs;

  bool get isSearchByVoterId => searchType.value == AppTexts.voterIdNumber;
  bool get isSearchByName => searchType.value == AppTexts.name;
  bool get isSearchByNameWithDob => searchType.value == AppTexts.nameWithDob;
  bool get isSearchByFatherName => searchType.value == AppTexts.fathersName;
  bool get isSearchByMotherName => searchType.value == AppTexts.mothersName;
  bool get isSearchByAddress => searchType.value == AppTexts.address;
  bool get isSearchByArea => searchType.value == AppTexts.area;

  int page = 1;
  final VoterHistoryService _historyService = VoterHistoryService();
  final NidOcrService _ocrService = NidOcrService();

  final RxBool isProcessingOcr = false.obs;
  final Rxn<File> selectedImage = Rxn<File>();

  // Address Search related variables
  final RxList<Map<String, dynamic>> wards = <Map<String, dynamic>>[].obs;
  final Rx<String?> selectedWard = Rx<String?>(null);

  // We will store the full area objects for the currently selected ward
  List<Map<String, dynamic>> _currentWardAreas = [];
  // availableAreas string list for the UI dropdown
  final RxList<String> availableAreas = <String>[].obs;
  final Rx<String?> selectedArea = Rx<String?>(null);

  // Gender filter for address search
  final Rx<String?> selectedGender = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    loadLocations();
  }

  Future<void> loadLocations() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json/location.json',
      );
      final data = await json.decode(response);
      wards.value = List<Map<String, dynamic>>.from(data['wards']);
    } catch (e) {
      debugPrint('Error loading locations: $e');
    }
  }

  void onWardSelected(String? wardName) {
    selectedWard.value = wardName;
    selectedArea.value = null; // Reset area when ward changes
    availableAreas.clear();
    _currentWardAreas.clear();

    if (wardName != null) {
      final wardData = wards.firstWhere(
        (ward) => ward['local_administrative_area'] == wardName,
        orElse: () => {},
      );

      if (wardData.isNotEmpty && wardData['areas'] != null) {
        // Updated parsing for new JSON structure: areas is List of Maps
        _currentWardAreas = List<Map<String, dynamic>>.from(wardData['areas']);
        availableAreas.value = _currentWardAreas
            .map((area) => area['voting_area_name'] as String)
            .toList();
      }
    }
  }

  Future<void> search({bool loadMore = false}) async {
    // ইউজারের কাঁচা ইনপুট (বাংলা/ইংরেজি মিলিয়ে যা আছে)
    final rawName = nameController.text;
    final rawDay = dayController.text;
    final rawMonth = monthController.text;
    final rawYear = yearController.text;

    // ভ্যালিডেশনের সুবিধার জন্য আগে ডিজিটগুলো ইংরেজিতে রূপান্তর করছি
    final dEn = DigitConverter.bnToEn(rawDay);
    final mEn = DigitConverter.bnToEn(rawMonth);
    final yEn = DigitConverter.bnToEn(rawYear);

    // Only nameWithDob, father's name, and mother's name require DOB
    bool isDateRequired =
        isSearchByNameWithDob || isSearchByFatherName || isSearchByMotherName;

    if (!isSearchByAddress && !isSearchByArea && Validators.isEmpty(rawName)) {
      _state.value = state.copyWith(error: 'সঠিক তথ্য প্রদান করুন');
      return;
    }

    if (isSearchByAddress && Validators.isEmpty(rawName)) {
      // Address search: text field is required
      _state.value = state.copyWith(error: 'অনুগ্রহ করে ঠিকানা লিখুন');
      return;
    }

    if (isSearchByArea) {
      // Area search: at least ward or area must be selected
      final hasWard =
          selectedWard.value != null && selectedWard.value!.isNotEmpty;
      final hasArea =
          selectedArea.value != null && selectedArea.value!.isNotEmpty;

      if (!hasWard && !hasArea) {
        _state.value = state.copyWith(
          error: 'অনুগ্রহ করে স্থানীয় প্রশাসন অথবা এলাকা নির্বাচন করুন',
        );
        return;
      }
    }

    // Dropdowns are now optional for Address search, so no validation needed for them.

    if (isDateRequired && !Validators.validDate(dEn, mEn, yEn)) {
      _state.value = state.copyWith(error: 'সঠিক জন্ম তারিখ প্রদান করুন');
      return;
    }

    if (loadMore && !state.hasMore) return;

    if (!loadMore) {
      page = 1; // Reset page on new search
      _state.value = state.copyWith(loading: true, error: null, voters: []);
    } else {
      _state.value = state.copyWith(loadingMore: true, error: null);
    }

    try {
      // API তে ডাটা সবসময় বাংলায় পাঠানোর জন্য
      // (ইউজার ইংরেজি ডিজিট লিখলে সেটাকেও বাংলায় কনভার্ট করছি)
      final searchValueBn = (isSearchByAddress || isSearchByArea)
          ? rawName
                .trim() // Address/Area is typed manually now, trim whitespace
          : DigitConverter.enToBn(rawName);

      debugPrint('Address search - searchValueBn: "$searchValueBn"');
      debugPrint('Address search - isSearchByAddress: $isSearchByAddress');

      final dobDayBn = DigitConverter.enToBn(dEn);
      final dobMonthBn = DigitConverter.enToBn(mEn);
      final dobYearBn = DigitConverter.enToBn(yEn);

      // CSRF token is automatically injected by Dio interceptor
      // No need to include _token in payload

      String apiSearchType;
      if (isSearchByVoterId) {
        apiSearchType = 'voter_id';
      } else if (isSearchByNameWithDob) {
        apiSearchType = 'name';
      } else if (isSearchByFatherName) {
        apiSearchType = 'fathers_name';
      } else if (isSearchByMotherName) {
        apiSearchType = 'mothers_name';
      } else if (isSearchByAddress) {
        apiSearchType = 'address';
      } else if (isSearchByArea) {
        apiSearchType = 'area';
      } else {
        apiSearchType = 'name';
      }

      final payload = {
        'search_type': apiSearchType,
        'search_value': searchValueBn,
        'dob_day': dobDayBn,
        'dob_month': dobMonthBn,
        'dob_year': dobYearBn,
        'page': page,
        'limit': 1000, // Increased limit per page for better results
      };

      if (isSearchByArea) {
        // Area search: include ward, area, and gender filters
        debugPrint('Area search payload - selectedWard: ${selectedWard.value}');
        debugPrint('Area search payload - selectedArea: ${selectedArea.value}');

        if (selectedWard.value != null) {
          payload['local_administrative_area'] = selectedWard.value!;
        }
        if (selectedArea.value != null) {
          // Pass the area name directly for vote_area_name matching
          payload['selected_area'] = selectedArea.value!;

          // Also pass area_id if available (for vote_area_no matching)
          final areaObj = _currentWardAreas.firstWhere(
            (element) => element['voting_area_name'] == selectedArea.value,
            orElse: () => {},
          );
          if (areaObj.isNotEmpty && areaObj['id'] != null) {
            payload['area_id'] = areaObj['id'];
          }
        }

        // Add gender filter if selected (convert Bengali to English for database)
        if (selectedGender.value != null && selectedGender.value!.isNotEmpty) {
          payload['gender'] = DigitConverter.genderToEnglish(
            selectedGender.value!,
          );
        }

        debugPrint('Area search final payload: $payload');
      }

      final res = await VoterLocalSource().search(payload);
      final newVoters = res['voters'] ?? [];
      final totalCount = res['total'] as int? ?? 0;
      final limit = payload['limit'] as int? ?? 1000;

      // If the API returns a list, we append it.
      // Often search APIs return everything or a specific page.
      // Assuming standard pagination behavior for the sake of the "Load More" feature requested.

      final finalVoters = loadMore
          ? [...state.voters, ...newVoters]
          : newVoters;

      // hasMore is true if we got a full page (limit results), indicating more might be available
      final hasMoreResults = newVoters.length >= limit;

      _state.value = state.copyWith(
        voters: finalVoters,
        hasMore: hasMoreResults,
        totalCount: totalCount,
        loading: false,
        loadingMore: false,
      );

      // Save to history only when not loading more (i.e., new search)
      if (!loadMore && finalVoters.isNotEmpty) {
        String historySearchType;
        if (isSearchByVoterId) {
          historySearchType = AppTexts.voterIdNumber;
        } else if (isSearchByFatherName) {
          historySearchType = AppTexts.fathersName;
        } else if (isSearchByMotherName) {
          historySearchType = AppTexts.mothersName;
        } else if (isSearchByAddress) {
          historySearchType = AppTexts.address;
        } else if (isSearchByArea) {
          historySearchType = AppTexts.area;
        } else if (isSearchByNameWithDob) {
          historySearchType = AppTexts.nameWithDob;
        } else {
          historySearchType = AppTexts.name;
        }

        await _historyService.saveSearch(
          searchType: historySearchType,
          searchValue: rawName,
          dobDay: rawDay,
          dobMonth: rawMonth,
          dobYear: rawYear,
          voters: finalVoters,
        );
      }

      if (newVoters.isNotEmpty) {
        page++;
      }
    } catch (e) {
      _state.value = state.copyWith(
        loading: false,
        loadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Pick image from camera and process OCR
  Future<void> pickImageAndExtractData() async {
    try {
      isProcessingOcr.value = true;

      // Pick image from camera
      final XFile? imageFile = await _ocrService.pickImageFromCamera();

      if (imageFile == null) {
        Get.snackbar(
          'সতর্কতা',
          'কোন ছবি নির্বাচন করা হয়নি',
          snackPosition: SnackPosition.BOTTOM,
        );
        isProcessingOcr.value = false;
        return;
      }

      selectedImage.value = File(imageFile.path);

      // Show processing message
      Get.snackbar(
        'প্রক্রিয়াকরণ',
        'ছবি থেকে তথ্য পড়া হচ্ছে...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Extract text from image
      final extractedText = await _ocrService.extractTextFromImage(
        imageFile.path,
      );

      if (extractedText.isEmpty) {
        Get.snackbar(
          'ত্রুটি',
          'ছবি থেকে কোনো লেখা পাওয়া যায়নি। দয়া করে আবার চেষ্টা করুন।',
          snackPosition: SnackPosition.BOTTOM,
        );
        isProcessingOcr.value = false;
        return;
      }

      // Parse the extracted text
      final parsedData = _ocrService.parseNidCardText(extractedText);

      // Auto-fill the form fields
      if (parsedData['name'] != null && parsedData['name']!.isNotEmpty) {
        nameController.text = parsedData['name']!;
      }

      if (parsedData['day'] != null && parsedData['day']!.isNotEmpty) {
        // Convert English digits to Bengali if needed
        dayController.text = DigitConverter.enToBn(parsedData['day']!);
      }

      if (parsedData['month'] != null && parsedData['month']!.isNotEmpty) {
        monthController.text = DigitConverter.enToBn(parsedData['month']!);
      }

      if (parsedData['year'] != null && parsedData['year']!.isNotEmpty) {
        yearController.text = DigitConverter.enToBn(parsedData['year']!);
      }

      // Show success message
      final name = parsedData['name'] ?? '';
      final day = parsedData['day'] ?? '';
      final month = parsedData['month'] ?? '';
      final year = parsedData['year'] ?? '';

      if (name.isNotEmpty ||
          (day.isNotEmpty && month.isNotEmpty && year.isNotEmpty)) {
        Get.snackbar(
          'সফল',
          'তথ্য স্বয়ংক্রিয়ভাবে পূরণ করা হয়েছে',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'সতর্কতা',
          'ছবি থেকে নাম বা জন্ম তারিখ পাওয়া যায়নি। দয়া করে নিজে লিখুন।',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      isProcessingOcr.value = false;
    } catch (e) {
      isProcessingOcr.value = false;
      Get.snackbar(
        'ত্রুটি',
        'ছবি প্রক্রিয়াকরণে সমস্যা হয়েছে: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    _ocrService.dispose();
    super.onClose();
  }
}
