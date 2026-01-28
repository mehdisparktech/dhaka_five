import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/voter_history_service.dart';

class VoterHistoryPresenter extends GetxController {
  final VoterHistoryService _historyService = VoterHistoryService();

  final RxList<Map<String, dynamic>> history = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isDownloading = false.obs;
  final RxBool isPrinting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  void loadHistory() {
    history.value = _historyService.getHistory();
  }

  Future<void> clearAllHistory() async {
    await _historyService.clearHistory();
    loadHistory();
    Get.snackbar(
      'সফল',
      'সব ইতিহাস মুছে ফেলা হয়েছে',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> deleteHistoryItem(String id) async {
    await _historyService.deleteHistoryItem(id);
    loadHistory();
    Get.snackbar(
      'সফল',
      'ইতিহাস মুছে ফেলা হয়েছে',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> downloadAllHistory() async {
    // Prevent multiple simultaneous calls
    if (isDownloading.value || isPrinting.value) {
      return;
    }

    if (history.isEmpty) {
      Get.snackbar(
        'সতর্কতা',
        'কোন ইতিহাস নেই',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isDownloading.value = true;

    try {
      final pdf = pw.Document();

      for (var historyItem in history) {
        final voters = historyItem['voters'] as List;
        if (voters.isEmpty) continue;

        // Add a page for each search
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) => [
              // Search info header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'খোঁজার তথ্য',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'খোঁজার ধরন: ${historyItem['searchType']}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'খোঁজার মান: ${historyItem['searchValue']}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'জন্ম তারিখ: ${historyItem['dobDay']}/${historyItem['dobMonth']}/${historyItem['dobYear']}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'খোঁজার তারিখ: ${_formatDate(historyItem['timestamp'])}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                  ],
                ),
              ),

              // Voters list
              pw.Text(
                'ফলাফল (${voters.length} টি)',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              // Table for voters
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'নাম',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'পিতা',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'ভোটার আইডি',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'ঠিকানা',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...voters.map((voter) {
                    final name = (voter['name'] ?? '').toString();
                    final fatherName = (voter['fathers_name'] ?? '').toString();
                    final voterId = (voter['voter_id'] ?? voter['serial'] ?? '')
                        .toString();
                    final address = (voter['address'] ?? '').toString();

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            name,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            fatherName,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            voterId,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            address,
                            style: const pw.TextStyle(fontSize: 9),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      }

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'voter_history_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      Get.snackbar(
        'সফল',
        'PDF ডাউনলোড হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'ত্রুটি',
        'PDF তৈরি করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  Future<void> printAllHistory() async {
    // Prevent multiple simultaneous calls
    if (isDownloading.value || isPrinting.value) {
      return;
    }

    if (history.isEmpty) {
      Get.snackbar(
        'সতর্কতা',
        'কোন ইতিহাস নেই',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isPrinting.value = true;

    try {
      await Printing.layoutPdf(
        onLayout: (format) async {
          final pdf = pw.Document();

          for (var historyItem in history) {
            final voters = historyItem['voters'] as List;
            if (voters.isEmpty) continue;

            pdf.addPage(
              pw.MultiPage(
                pageFormat: format,
                margin: const pw.EdgeInsets.all(20),
                build: (context) => [
                  pw.Header(
                    level: 0,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'খোঁজার তথ্য',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'খোঁজার ধরন: ${historyItem['searchType']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'খোঁজার মান: ${historyItem['searchValue']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'জন্ম তারিখ: ${historyItem['dobDay']}/${historyItem['dobMonth']}/${historyItem['dobYear']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'খোঁজার তারিখ: ${_formatDate(historyItem['timestamp'])}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Divider(),
                        pw.SizedBox(height: 8),
                      ],
                    ),
                  ),
                  pw.Text(
                    'ফলাফল (${voters.length} টি)',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'নাম',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'পিতা',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'ভোটার আইডি',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'ঠিকানা',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...voters.map((voter) {
                        final name = (voter['name'] ?? '').toString();
                        final fatherName = (voter['fathers_name'] ?? '')
                            .toString();
                        final voterId =
                            (voter['voter_id'] ?? voter['serial'] ?? '')
                                .toString();
                        final address = (voter['address'] ?? '').toString();

                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                name,
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                fatherName,
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                voterId,
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                address,
                                style: const pw.TextStyle(fontSize: 9),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );
          }

          return pdf.save();
        },
      );

      Get.snackbar(
        'সফল',
        'প্রিন্ট করা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'ত্রুটি',
        'প্রিন্ট করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPrinting.value = false;
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'তারিখ নেই';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return isoString;
    }
  }
}
