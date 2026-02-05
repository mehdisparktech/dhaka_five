import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_texts.dart';
import '../../../../core/services/nid_ocr_service.dart';
import '../../../../core/utils/digit_converter.dart';
import '../../../../core/utils/validators.dart';
import '../../data/voter_history_service.dart';
import '../../data/voter_remote_source.dart';
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
  bool get isSearchByFatherName => searchType.value == AppTexts.fathersName;
  bool get isSearchByMotherName => searchType.value == AppTexts.mothersName;

  int page = 1;
  final VoterHistoryService _historyService = VoterHistoryService();
  final NidOcrService _ocrService = NidOcrService();

  final RxBool isProcessingOcr = false.obs;
  final Rxn<File> selectedImage = Rxn<File>();

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

    if (Validators.isEmpty(rawName) || !Validators.validDate(dEn, mEn, yEn)) {
      _state.value = state.copyWith(error: 'সঠিক তথ্য প্রদান করুন');
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
      // NOTE: The API endpoint structure in the request was vague about pagination parameters.
      // Assuming straightforward payload for now, or maybe the API doesn't support pagination
      // in the way typical list APIs do.
      // The user code sample showed `search` taking `page` but the remote source implementation
      // in the prompt sample code used a payload map.
      // I will adapt the RemoteSource to take the payload including page if needed,
      // but for now I will stick to the prompts logic which used a payload map.
      // Re-reading user prompt: "VoterRemoteSource().search(page)" was used in the Presenter example,
      // but "VoterRemoteSource().search({...})" was used in the RemoteSource definition.
      // I will reconcile this by passing the payload.

      // API তে ডাটা সবসময় বাংলায় পাঠানোর জন্য
      // (ইউজার ইংরেজি ডিজিট লিখলে সেটাকেও বাংলায় কনভার্ট করছি)
      final searchValueBn = DigitConverter.enToBn(rawName);
      final dobDayBn = DigitConverter.enToBn(dEn);
      final dobMonthBn = DigitConverter.enToBn(mEn);
      final dobYearBn = DigitConverter.enToBn(yEn);

      // CSRF token is automatically injected by Dio interceptor
      // No need to include _token in payload

      String apiSearchType;
      if (isSearchByVoterId) {
        apiSearchType = 'voter_id';
      } else if (isSearchByFatherName) {
        apiSearchType = 'fathers_name';
      } else if (isSearchByMotherName) {
        apiSearchType = 'mothers_name';
      } else {
        apiSearchType = 'name';
      }

      final payload = {
        'search_type': apiSearchType,
        'search_value': searchValueBn,
        'dob_day': dobDayBn,
        'dob_month': dobMonthBn,
        'dob_year': dobYearBn,
        // 'page': page, // If the API supports it
      };

      final res = await VoterRemoteSource().search(payload);
      final newVoters = res['voters'] ?? [];

      // If the API returns a list, we append it.
      // Often search APIs return everything or a specific page.
      // Assuming standard pagination behavior for the sake of the "Load More" feature requested.

      final finalVoters = loadMore
          ? [...state.voters, ...newVoters]
          : newVoters;

      _state.value = state.copyWith(
        voters: finalVoters,
        hasMore: newVoters.isNotEmpty, // Simple pagination check
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
