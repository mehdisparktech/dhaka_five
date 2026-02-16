import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class NidOcrService {
  static final NidOcrService _instance = NidOcrService._internal();
  factory NidOcrService() => _instance;
  NidOcrService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  // Note: Newer versions of google_mlkit_text_recognition removed the
  // Bengali-specific script enum. Use the Latin script (multi-language)
  // recognizer which can still read many Unicode scripts including Bangla.
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        return null;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  /// Extract text from image using OCR
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String fullText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          fullText += '${line.text}\n';
        }
      }

      return fullText.trim();
    } catch (e) {
      return '';
    }
  }

  /// Parse NID card text to extract name and DOB
  Map<String, String> parseNidCardText(String ocrText) {
    String name = '';
    String dob = '';
    String day = '';
    String month = '';
    String year = '';

    // Clean the text
    final lines = ocrText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    // Try to find name - usually appears early in the text
    // Look for patterns like "নাম:", "Name:", or lines that look like names
    //
    // For cards like the given example:
    //   "গণপ্রজাতন্ত্রী বাংলাদেশ সরকার"
    //   "Government of the People's Republic of Bangladesh"
    //   "National ID Card / জাতীয় পরিচয় পত্র"
    //   "নাম: মোঃ মেহেদী হাসান"
    //   "Name: MD. MEHDI HASAN"
    // আমরা আগে উপরের header/text গুলো বাদ দিয়ে
    // বাংলা "নাম:" / ইংরেজি "Name:" লাইনটা ধরার চেষ্টা করি।
    for (int i = 0; i < lines.length && i < 15; i++) {
      final line = lines[i].trim();

      // কিছু খুব common header লাইন একদমই স্কিপ করে দিচ্ছি
      final lower = line.toLowerCase();
      if (lower.contains('government of the people') ||
          lower.contains('government of the') ||
          lower.contains('republic of bangladesh') ||
          lower.contains('national id card') ||
          lower.contains('id card') ||
          line.contains('গণপ্রজাতন্ত্রী') ||
          line.contains('বাংলাদেশ সরকার') ||
          line.contains('জাতীয় পরিচয় পত্র')) {
        continue;
      }

      // 1) বাংলা "নাম:" সাইন সহ একই লাইনে থাকলে সেখান থেকে কেটে নেওয়া
      if (line.contains('নাম')) {
        // উদাহরণ: "নাম: মোঃ মেহেদী হাসান"
        final parts = line.split(RegExp(r'[:：]'));
        if (parts.length > 1) {
          name = parts.sublist(1).join(':').trim();
        }

        // যদি কোন কারণে কোলন না পাই, fallback হিসেবে পরের লাইন ধরব
        if (name.isEmpty && i + 1 < lines.length) {
          name = lines[i + 1].trim();
        }

        // Common prefix/suffix clean
        name = name.replaceAll(RegExp(r'^[নামName::\s]+'), '');
        name = name.replaceAll(RegExp(r'[:\s]+$'), '');

        if (name.isNotEmpty) {
          break;
        }
      }

      // 2) ইংরেজি "Name:" লাইন থেকে নাম নেওয়া (যদি এর আগের লুপে বাংলা নাম না পাওয়া যায়)
      if (name.isEmpty &&
          (line.startsWith('Name') ||
              line.startsWith('NAME') ||
              line.contains('Name:'))) {
        final parts = line.split(RegExp(r'[:：]'));
        if (parts.length > 1) {
          name = parts.sublist(1).join(':').trim();
          name = name.replaceAll(RegExp(r'[:\s]+$'), '');
          if (name.isNotEmpty) {
            break;
          }
        }
      }

      // If no label found, try to identify name by pattern
      // Names usually don't contain numbers and are 3-50 characters
      if (name.isEmpty &&
          !line.contains(RegExp(r'\d')) &&
          line.length > 3 &&
          line.length < 50 &&
          !line.contains('জাতীয়') &&
          !line.contains('পরিচয়') &&
          !line.contains('কার্ড')) {
        // This might be the name
        name = line;
        break;
      }
    }

    // যদি এখানে এসেও name ফাঁকা থাকে, তাহলে উপরের generic pattern
    // ম্যাচের মাধ্যমে সেট করার চেষ্টা করা হবে (নিচের কোডে আছে)।

    // Try to find DOB - look for date patterns
    // Common patterns:
    //  - DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    //  - DD MonthName YYYY  (যেমন: "13 May 1998")
    final datePatterns = [
      RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})'), // DD/MM/YYYY
      RegExp(r'(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})'), // YYYY/MM/DD
      RegExp(r'(\d{1,2})\s+(\d{1,2})\s+(\d{4})'), // DD MM YYYY (numeric month)
      RegExp(r'(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})'), // DD MonthName YYYY
    ];

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          if (pattern == datePatterns[1]) {
            // YYYY/MM/DD format
            year = match.group(1) ?? '';
            month = match.group(2) ?? '';
            day = match.group(3) ?? '';
          } else if (pattern == datePatterns[3]) {
            // DD MonthName YYYY (e.g., 13 May 1998)
            day = match.group(1) ?? '';
            final monthName = (match.group(2) ?? '').toLowerCase();
            year = match.group(3) ?? '';

            const monthMap = {
              'january': '01',
              'february': '02',
              'march': '03',
              'april': '04',
              'may': '05',
              'june': '06',
              'july': '07',
              'august': '08',
              'september': '09',
              'october': '10',
              'november': '11',
              'december': '12',
              // short names
              'jan': '01',
              'feb': '02',
              'mar': '03',
              'apr': '04',
              'jun': '06',
              'jul': '07',
              'aug': '08',
              'sep': '09',
              'sept': '09',
              'oct': '10',
              'nov': '11',
              'dec': '12',
            };
            month = monthMap[monthName] ?? '';
          } else {
            // DD/MM/YYYY or DD MM YYYY numeric formats
            day = match.group(1) ?? '';
            month = match.group(2) ?? '';
            year = match.group(3) ?? '';
          }

          // Validate date
          final d = int.tryParse(day);
          final m = int.tryParse(month);
          final y = int.tryParse(year);

          if (d != null &&
              m != null &&
              y != null &&
              d >= 1 &&
              d <= 31 &&
              m >= 1 &&
              m <= 12 &&
              y >= 1900 &&
              y <= 2100) {
            dob = line.trim();
            break;
          }
        }
      }
      if (dob.isNotEmpty) break;
    }

    // Also look for Bengali date patterns
    if (dob.isEmpty) {
      for (final line in lines) {
        // Look for Bengali digits in date format
        // Pattern: বাংলা-সংখ্যা/বাংলা-সংখ্যা/বাংলা-সংখ্যা
        final bengaliDatePattern = RegExp(
          r'[০-৯]{1,2}[/\-\.][০-৯]{1,2}[/\-\.][০-৯]{4}',
        );
        final match = bengaliDatePattern.firstMatch(line);
        if (match != null) {
          dob = match.group(0) ?? '';
          // Convert Bengali digits to English
          final dateParts = dob.split(RegExp(r'[/\-\.]'));
          if (dateParts.length == 3) {
            day = _bengaliToEnglish(dateParts[0]);
            month = _bengaliToEnglish(dateParts[1]);
            year = _bengaliToEnglish(dateParts[2]);
          }
          break;
        }
      }
    }

    // Look for "জন্ম তারিখ" or "Date of Birth" labels
    if (dob.isEmpty) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.contains('জন্ম') ||
            line.contains('তারিখ') ||
            line.contains('Date of Birth') ||
            line.contains('DOB')) {
          // Check current line and next few lines for date
          for (int j = i; j < lines.length && j < i + 3; j++) {
            final dateLine = lines[j];
            for (final pattern in datePatterns) {
              final match = pattern.firstMatch(dateLine);
              if (match != null) {
                if (pattern == datePatterns[1]) {
                  year = match.group(1) ?? '';
                  month = match.group(2) ?? '';
                  day = match.group(3) ?? '';
                } else {
                  day = match.group(1) ?? '';
                  month = match.group(2) ?? '';
                  year = match.group(3) ?? '';
                }
                dob = dateLine.trim();
                break;
              }
            }
            if (dob.isNotEmpty) break;
          }
          break;
        }
      }
    }

    // যদি এখনো name টা purely ইংরেজি থাকে এবং কোনো বাংলা অক্ষর না থাকে,
    // তাহলে তাকে আনুমানিক বাংলায় transliterate করার চেষ্টা করা হবে।
    if (name.isNotEmpty && !_containsBangla(name)) {
      name = _englishNameToBangla(name);
    }

    return {'name': name, 'dob': dob, 'day': day, 'month': month, 'year': year};
  }

  /// Convert Bengali digits to English
  String _bengaliToEnglish(String bengali) {
    const Map<String, String> bengaliToEnglish = {
      '০': '0',
      '১': '1',
      '২': '2',
      '৩': '3',
      '৪': '4',
      '৫': '5',
      '৬': '6',
      '৭': '7',
      '৮': '8',
      '৯': '9',
    };

    String result = '';
    for (int i = 0; i < bengali.length; i++) {
      result += bengaliToEnglish[bengali[i]] ?? bengali[i];
    }
    return result;
  }

  /// Check if text already contains any Bangla characters
  bool _containsBangla(String text) {
    return RegExp(r'[অ-হ০-৯]').hasMatch(text);
  }

  /// Very simple English → Bangla name transliteration helper.
  ///
  /// লক্ষ্য: ১০০% শুদ্ধ বানান না, বরং NID কার্ডের মত সাধারণ নামগুলো
  /// আনুমানিক বাংলায় দেখানো। উদাহরণ:
  /// "MD. MEHDI HASAN" -> "মোঃ মেহেদী হাসান"
  String _englishNameToBangla(String name) {
    final cleaned = name
        .replaceAll('.', ' ')
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return name;

    const Map<String, String> wordMap = {
      'MD': 'মোঃ',
      'MD.': 'মোঃ',
      'MUHAMMAD': 'মুহাম্মদ',
      'MOHAMMAD': 'মোহাম্মদ',
      'MOHAMMED': 'মোহাম্মদ',
      'MEHEDI': 'মেহেদী',
      'MEHDI': 'মেহেদী',
      'MEHIDI': 'মেহেদী',
      'HASAN': 'হাসান',
      'HASSAN': 'হাসান',
      'HOSSAIN': 'হোসেন',
      'HOSSAIN.': 'হোসেন',
      'HUSSAIN': 'হুসাইন',
      'ALI': 'আলী',
      'AL': 'আল',
      'AHMED': 'আহমেদ',
      'AHMAD': 'আহমাদ',
      'KARIM': 'করিম',
      'RAHMAN': 'রহমান',
      'ISLAM': 'ইসলাম',
    };

    final parts = cleaned.split(' ');
    final List<String> banglaParts = [];

    for (final raw in parts) {
      if (raw.isEmpty) continue;
      final upper = raw.toUpperCase();
      final mapped = wordMap[upper];
      if (mapped != null) {
        banglaParts.add(mapped);
      } else {
        // Generic fallback: আনুমানিক অক্ষরভিত্তিক transliteration
        banglaParts.add(_basicEnglishToBangla(raw));
      }
    }

    return banglaParts.join(' ');
  }

  /// খুবই simple, অক্ষরভিত্তিক English → Bangla transliteration।
  /// এটা সব নামের জন্য perfect হবে না, কিন্তু "RAHIM", "KARIM"
  /// এর মত common নামগুলো কিছুটা বাংলা আকৃতিতে দেখাবে।
  String _basicEnglishToBangla(String word) {
    if (word.isEmpty) return word;

    final lower = word.toLowerCase();
    final StringBuffer buffer = StringBuffer();

    // আগে common দুই-অক্ষরের sound গুলো ধরার চেষ্টা করি
    const Map<String, String> digraphMap = {
      'kh': 'খ',
      'sh': 'শ',
      'ch': 'চ',
      'th': 'থ',
      'ph': 'ফ',
      'bh': 'ভ',
      'dh': 'ধ',
      'gh': 'ঘ',
    };

    const Map<String, String> charMap = {
      'a': 'া',
      'b': 'ব',
      'c': 'ক',
      'd': 'দ',
      'e': 'ে',
      'f': 'ফ',
      'g': 'গ',
      'h': 'হ',
      'i': 'ি',
      'j': 'জ',
      'k': 'ক',
      'l': 'ল',
      'm': 'ম',
      'n': 'ন',
      'o': 'ো',
      'p': 'প',
      'q': 'ক',
      'r': 'র',
      's': 'স',
      't': 'ত',
      'u': 'ু',
      'v': 'ভ',
      'w': 'উ',
      'x': 'ক্স',
      'y': 'ই',
      'z': 'জ',
    };

    int i = 0;
    while (i < lower.length) {
      // দুই অক্ষরের combination আগে চেক করি
      if (i + 1 < lower.length) {
        final pair = lower.substring(i, i + 2);
        final mappedDigraph = digraphMap[pair];
        if (mappedDigraph != null) {
          buffer.write(mappedDigraph);
          i += 2;
          continue;
        }
      }

      final ch = lower[i];
      buffer.write(charMap[ch] ?? ch);
      i++;
    }

    return buffer.toString();
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
