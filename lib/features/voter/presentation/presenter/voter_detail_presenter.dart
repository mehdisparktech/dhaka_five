import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/services/thermal_printer_service.dart';

class VoterDetailPresenter extends GetxController {
  final Map voter;
  final GlobalKey previewKey = GlobalKey();

  VoterDetailPresenter({required this.voter});

  final RxBool isDownloading = false.obs;
  final RxBool isPrinting = false.obs;

  String _field(String key, {String fallback = 'তথ্য নেই'}) {
    final value = voter[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty) return fallback;
    return text;
  }

  String get name => _field('name', fallback: 'নাম পাওয়া যায়নি');
  String get fatherName => _field('fathers_name');
  String get motherName => _field('mothers_name');
  String get husbandName => _field('husband_name', fallback: 'প্রযোজ্য নয়');
  String get voterId =>
      _field('voter_id', fallback: _field('serial', fallback: '-'));
  String get serial => _field('serial', fallback: '-');
  String get dob =>
      _field('dob', fallback: _field('date_of_birth', fallback: '-'));
  String get gender => _field('gender', fallback: '-');
  String get address => _field('address');

  String get area {
    final areaData = voter['area'];
    if (areaData is Map) {
      final local = areaData['local_administrative_area']?.toString().trim();
      if (local != null && local.isNotEmpty) {
        return local;
      }
    }
    return _field('area', fallback: 'তথ্য নেই');
  }

  String get centerName {
    final voteCenter = voter['vote_center'];
    if (voteCenter is Map) {
      final raw = voteCenter['name']?.toString().trim();
      if (raw != null && raw.isNotEmpty) {
        return raw;
      }
    }

    final flatCenterName = _field('center_name', fallback: '');
    if (flatCenterName.isNotEmpty) {
      return flatCenterName;
    }
    final flatCenter = _field('center', fallback: '');
    if (flatCenter.isNotEmpty) {
      return flatCenter;
    }
    return 'তথ্য নেই';
  }

  String get centerInfo {
    final directInfo = _field('center_info', fallback: '');
    if (directInfo.isNotEmpty) return directInfo;

    final parts = <String>[];

    final voteCenter = voter['vote_center'];
    if (voteCenter is Map) {
      final centerNo = voteCenter['center_no']?.toString().trim();
      if (centerNo != null && centerNo.isNotEmpty) {
        parts.add('কেন্দ্র নং: $centerNo');
      }
    }

    final areaData = voter['area'];
    if (areaData is Map) {
      final localArea = areaData['local_administrative_area']
          ?.toString()
          .trim();
      if (localArea != null && localArea.isNotEmpty) {
        parts.add(localArea);
      }

      final constituency = areaData['constituency'];
      if (constituency is Map) {
        final number = constituency['number']?.toString().trim();
        final name = constituency['name']?.toString().trim();
        final cParts = <String>[];
        if (number != null && number.isNotEmpty) cParts.add(number);
        if (name != null && name.isNotEmpty) cParts.add(name);
        if (cParts.isNotEmpty) {
          parts.add(cParts.join(' - '));
        }
      }
    }

    return parts.join(', ');
  }

  Future<Uint8List> buildPdf(PdfPageFormat format) async {
    final boundary =
        previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Preview not ready');
    }

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) =>
            pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
      ),
    );

    return pdf.save();
  }

  Future<void> downloadPdf() async {
    if (isDownloading.value) return;

    isDownloading.value = true;

    try {
      final bytes = await buildPdf(PdfPageFormat.a4);
      await Printing.sharePdf(bytes: bytes, filename: 'voter_$voterId.pdf');
    } catch (e) {
      Get.snackbar(
        'ত্রুটি',
        'PDF তৈরি করতে সমস্যা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  Future<void> printPdf() async {
    if (isPrinting.value) return;

    isPrinting.value = true;

    try {
      await Printing.layoutPdf(onLayout: buildPdf);
    } catch (e) {
      Get.snackbar(
        'ত্রুটি',
        'প্রিন্ট করতে সমস্যা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPrinting.value = false;
    }
  }

  // Thermal Printer Logic
  final ThermalPrinterService _thermalService = ThermalPrinterService.instance;
  // Use generic List or dynamic if BluetoothInfo is not exported, but generally it is.
  // To avoid import issues in presenter, we can use dynamic or basic types,
  // but better to import print_bluetooth_thermal in presenter if needed.
  // Actually, let's use dynamic to be safe and avoid unnecessary imports if not needed,
  // BUT we need to display name and mac.
  // Let's import the package in the file header first.

  final RxList<dynamic> availableDevices = <dynamic>[].obs;
  final RxBool isScanning = false.obs;
  final RxBool isThermalPrinting = false.obs;

  Future<void> scanForPrinters() async {
    isScanning.value = true;
    try {
      final permitted = await _thermalService.isPermissionGranted;
      if (!permitted) {
        // print_bluetooth_thermal handles request internally sometimes, but let's check
        // It provides a method to check. If false, we might need to ask user to enable bluetooth.
        // Actually the package assumes permissions are requested.
        // Let's rely on getBondedDevices() which usually triggers checks or returns empty.
      }

      final devices = await _thermalService.getBondedDevices();
      availableDevices.assignAll(devices);

      if (devices.isEmpty) {
        Get.snackbar(
          'device পাওয়া যায়নি',
          'অনুগ্রহ করে প্রিন্টার পেয়ার (Pair) করুন',
        );
      }
    } catch (e) {
      Get.snackbar('ত্রুটি', 'ডিভাইস খুঁজতে সমস্যা হয়েছে: $e');
    } finally {
      isScanning.value = false;
    }
  }

  Future<void> connectToPrinter(String mac) async {
    try {
      final success = await _thermalService.connect(mac);
      if (success) {
        Get.back(); // Close dialog
        Get.snackbar(
          'সফল',
          'প্রিন্টার সংযুক্ত হয়েছে',
          backgroundColor: Colors.green.withOpacity(0.2),
        );
      } else {
        Get.snackbar('ব্যর্থ', 'সংযোগ করা যায়নি');
      }
    } catch (e) {
      Get.snackbar('ত্রুটি', 'সংযোগ সমস্যা: $e');
    }
  }

  Future<void> printThermalSlip() async {
    if (isThermalPrinting.value) return;

    // Check connection first
    final bool connected = await _thermalService.isConnected;

    if (!connected) {
      await scanForPrinters();
      _showPrinterDialog();
      return;
    }

    isThermalPrinting.value = true;
    try {
      await _thermalService.printVoterSlip(voter);
      Get.snackbar(
        'সফল',
        'প্রিন্ট সম্পন্ন হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('ত্রুটি', 'প্রিন্ট করতে সমস্যা হয়েছে: $e');
    } finally {
      isThermalPrinting.value = false;
    }
  }

  void _showPrinterDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'প্রিন্টার নির্বাচন করুন',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (isScanning.value) return const CircularProgressIndicator();
                if (availableDevices.isEmpty) {
                  return const Text(
                    'কোনো পেয়ার করা ডিভাইস মিলেনি।\nব্লুটুথ অন আছে কিনা দেখুন।',
                  );
                }

                return Column(
                  children: availableDevices.map((device) {
                    // device is BluetoothInfo
                    final name = device.name;
                    final mac = device
                        .macAdress; // Note: package might spell it 'macAdress' or 'macAddress'
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(mac),
                      onTap: () => connectToPrinter(mac),
                      trailing: const Icon(Icons.print),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                      _showReceiptPreview();
                    },
                    child: const Text('রিসিট প্রিভিউ'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('বন্ধ করুন'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptPreview() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: SingleChildScrollView(
          child: Container(
            width: 300, // Approximate width for 58mm style preview on phone
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ভোটার স্লিপ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'ঢাকা ৫ আসন',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'তারিখ: ${_formatDate(DateTime.now())}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                const Divider(color: Colors.black, thickness: 1),
                _buildPreviewRow('সিরিয়াল:', serial),
                _buildPreviewRow('নাম:', name),
                _buildPreviewRow('পিতা:', fatherName),
                _buildPreviewRow('মা:', motherName),
                _buildPreviewRow('লিঙ্গ:', gender),
                _buildPreviewRow('এলাকা:', area),
                _buildPreviewRow('জন্ম তারিখ:', dob),
                _buildPreviewRow('ভোটার নং:', voterId),
                //_buildPreviewRow('Address:', address),
                const Divider(color: Colors.black, thickness: 1),
                const Text(
                  'কেন্দ্র:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Text(
                  centerName,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
                const Divider(color: Colors.black, thickness: 1),
                const SizedBox(height: 16),
                const Text(
                  'ধন্যবাদ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime now) {
    String formatted =
        "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";
    return _toBanglaNumber(formatted);
  }

  String _toBanglaNumber(String input) {
    const eng = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bang = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

    for (int i = 0; i < eng.length; i++) {
      input = input.replaceAll(eng[i], bang[i]);
    }
    return input;
  }
}
