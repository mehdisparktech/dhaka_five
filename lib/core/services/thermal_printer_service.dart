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

    // 1. Header
    bytes += generator.reset();
    bytes += generator.text(
      'VOTER SLIP',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'Dhaka Five App',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(1);

    // 2. Date
    final now = DateTime.now();
    final dateStr =
        "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";
    bytes += generator.text(
      'Date: $dateStr',
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

    addRow('Name:', val('name'));
    addRow('Father:', val('fathers_name'));
    addRow('Mother:', val('mothers_name'));
    addRow('Serial:', val('serial'));
    addRow('Voter No:', val('voter_id', def: val('serial')));
    addRow('Phone:', val('phone'));

    bytes += generator.hr();

    // Center Logic
    String center = val('center_name');
    if (center == '-') {
      if (voter['vote_center'] is Map) {
        center = voter['vote_center']['name'] ?? '-';
      }
    }

    bytes += generator.text('Center:', styles: const PosStyles(bold: true));
    bytes += generator.text(
      center,
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.hr();
    bytes += generator.text(
      'Thank You',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    await PrintBluetoothThermal.writeBytes(bytes);
  }
}
