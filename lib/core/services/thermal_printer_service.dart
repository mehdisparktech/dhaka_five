import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class ThermalPrinterService {
  ThermalPrinterService._();
  static final ThermalPrinterService instance = ThermalPrinterService._();

  // Connection status stream is not directly available in this package as a stream in the same way,
  // but we can check status. For now, we'll rely on method calls.
  // or implement a polling mechanism if strictly needed, but for receipts, on-demand connection is often fine.

  Future<bool> get isPermissionGranted async =>
      await PrintBluetoothThermal.isPermissionBluetoothGranted;

  Future<bool> get isConnected async =>
      await PrintBluetoothThermal.connectionStatus;

  Future<List<BluetoothInfo>> getBondedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> connect(String macAddress) async {
    return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  Future<bool> disconnect() async {
    return await PrintBluetoothThermal.disconnect;
  }

  Future<void> printVoterSlip(Map voter) async {
    final bool connected = await isConnected;
    if (!connected) return;

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Helper to extract data
    String val(String key, {String def = '-'}) {
      var v = voter[key];
      if (v == null) return def;
      return v.toString().trim().isEmpty ? def : v.toString().trim();
    }

    // Logic for Area
    String getArea() {
      final areaData = voter['area'];
      if (areaData is Map) {
        final local = areaData['local_administrative_area']?.toString().trim();
        if (local != null && local.isNotEmpty) {
          return local;
        }
      }
      return val('area', def: 'তথ্য নেই');
    }

    // Logic for Center
    String getCenter() {
      final voteCenter = voter['vote_center'];
      if (voteCenter is Map) {
        final raw = voteCenter['name']?.toString().trim();
        if (raw != null && raw.isNotEmpty) {
          return raw;
        }
      }
      final flatCenterName = val('center_name', def: '');
      if (flatCenterName.isNotEmpty) return flatCenterName;
      final flatCenter = val('center', def: '');
      if (flatCenter.isNotEmpty) return flatCenter;
      return 'তথ্য নেই';
    }

    // 1. Header
    bytes += generator.reset();
    bytes += generator.text(
      'ভোটার স্লিপ', // Voter Slip
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'ঢাকা ৫ আসন', // Dhaka 5 Asan
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(1);

    // 2. Date
    final now = DateTime.now();
    final dateStr =
        "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";
    bytes += generator.text(
      'তারিখ: ${_toBanglaNumber(dateStr)}', // Date
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    );
    bytes += generator.hr();

    // 3. Details
    void addRow(String label, String value) {
      bytes += generator.row([
        PosColumn(
          text: label,
          width: 4,
          styles: const PosStyles(bold: true, fontType: PosFontType.fontB),
        ),
        PosColumn(
          text: value,
          width: 8,
          styles: const PosStyles(
            align: PosAlign.right,
            fontType: PosFontType.fontB,
          ),
        ),
      ]);
    }

    // Field Order: Serial, Name, Father, Mother, Gender, Area, DOB, Voter No

    addRow('সিরিয়াল:', val('serial', def: '-'));
    addRow('নাম:', val('name', def: 'নাম পাওয়া যায়নি'));
    addRow('পিতা:', val('fathers_name'));
    addRow('মা:', val('mothers_name'));
    addRow('লিঙ্গ:', val('gender', def: '-'));
    addRow('এলাকা:', getArea());
    addRow('জন্ম তারিখ:', val('dob', def: val('date_of_birth', def: '-')));

    String vNo = val('voter_id');
    if (vNo == '-') {
      vNo = val('serial', def: '-');
    }
    addRow('ভোটার নং:', vNo);

    bytes += generator.hr();

    // Center Logic
    bytes += generator.text('কেন্দ্র:', styles: const PosStyles(bold: true));
    bytes += generator.text(
      getCenter(),
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.hr();
    bytes += generator.text(
      'ধন্যবাদ', // Thank You
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    await PrintBluetoothThermal.writeBytes(bytes);
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
