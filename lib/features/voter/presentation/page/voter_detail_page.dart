import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';

class VoterDetailPage extends StatefulWidget {
  final Map voter;

  const VoterDetailPage({super.key, required this.voter});

  @override
  State<VoterDetailPage> createState() => _VoterDetailPageState();
}

class _VoterDetailPageState extends State<VoterDetailPage> {
  final GlobalKey _previewKey = GlobalKey();

  Map get voter => widget.voter;

  String _field(String key, {String fallback = 'তথ্য নেই'}) {
    final value = voter[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty) return fallback;
    return text;
  }

  String get _name => _field('name', fallback: 'নাম পাওয়া যায়নি');
  String get _fatherName => _field('fathers_name');
  String get _motherName => _field('mothers_name');
  String get _husbandName => _field('husband_name', fallback: 'প্রযোজ্য নয়');
  String get _voterId =>
      _field('voter_id', fallback: _field('serial', fallback: '-'));
  String get _serial => _field('serial', fallback: '-');
  String get _dob =>
      _field('dob', fallback: _field('date_of_birth', fallback: '-'));
  String get _gender => _field('gender', fallback: '-');
  String get _address => _field('address');
  String get _area {
    final area = voter['area'];
    if (area is Map) {
      final local = area['local_administrative_area']?.toString().trim();
      if (local != null && local.isNotEmpty) {
        return local;
      }
    }
    // যদি কখনও API সরাসরি "area" স্ট্রিং হিসেবে ফেরত দেয় বা কিছুই না থাকে
    return _field('area', fallback: 'তথ্য নেই');
  }

  String get _centerName {
    // নতুন API: vote_center.name, পুরোনো ফ্ল্যাট ফরম্যাট: center_name / center
    final voteCenter = voter['vote_center'];
    if (voteCenter is Map) {
      final raw = voteCenter['name']?.toString().trim();
      if (raw != null && raw.isNotEmpty) {
        return raw;
      }
    }

    // পুরোনো ফ্ল্যাট কী থেকে ফ্যালব্যাক
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

  String get _centerInfo {
    // আগে center_info থাকলে সরাসরি সেটাই দেখাই
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

    final area = voter['area'];
    if (area is Map) {
      final localArea = area['local_administrative_area']?.toString().trim();
      if (localArea != null && localArea.isNotEmpty) {
        parts.add(localArea);
      }

      final constituency = area['constituency'];
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

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final boundary =
        _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
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

  Future<void> _downloadPdf() async {
    try {
      final bytes = await _buildPdf(PdfPageFormat.a4);
      await Printing.sharePdf(bytes: bytes, filename: 'voter_$_voterId.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF তৈরি করতে সমস্যা হয়েছে')),
      );
    }
  }

  Future<void> _printPdf() async {
    try {
      await Printing.layoutPdf(onLayout: _buildPdf);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('প্রিন্ট করতে সমস্যা হয়েছে')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ভোটারের তথ্য'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: RepaintBoundary(
            key: _previewKey,
            child: Container(
              padding: const EdgeInsets.all(8),
              width: 430,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF09575b), width: 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top banner (candidate + slogan) – using existing cover image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 230,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/images/cover.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'কেন্দ্রের তথ্য',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _centerName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_centerInfo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _centerInfo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(label: 'নাম', value: _name),
                        _InfoRow(label: 'সিরিয়াল নং', value: _serial),
                        _InfoRow(label: 'পিতা', value: _fatherName),
                        _InfoRow(label: 'মাতা', value: _motherName),
                        _InfoRow(label: 'স্বামী/স্ত্রী', value: _husbandName),
                        _InfoRow(label: 'ভোটার নং', value: _voterId),
                        _InfoRow(label: 'জন্ম তারিখ', value: _dob),
                        _InfoRow(label: 'লিঙ্গ', value: _gender),
                        _InfoRow(label: 'এলাকাঃ', value: _area),
                        _InfoRow(label: 'ঠিকানা', value: _address),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Expanded(
                      child: Text(
                        '''মোহাম্মদ কামাল হোসেন এর সালাম নিন, দাঁড়িপাল্লা মার্কায় ভোট দিন।তারুন্যের প্রথম ভোট, দাঁড়িপাল্লা মার্কার পক্ষে হোক।''',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('PDF ডাউনলোড'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _printPdf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('প্রিন্ট'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
