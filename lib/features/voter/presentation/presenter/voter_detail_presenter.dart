import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
}
