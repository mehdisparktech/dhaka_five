class Validators {
  static bool isEmpty(String v) => v.trim().isEmpty;

  static bool validDate(String d, String m, String y) {
    if (d.isEmpty || m.isEmpty || y.isEmpty) return false;
    if (d.length > 2 || m.length > 2 || y.length != 4) return false;

    final day = int.tryParse(d);
    final month = int.tryParse(m);
    final year = int.tryParse(y);

    if (day == null || month == null || year == null) return false;
    if (day < 1 || day > 31) return false;
    if (month < 1 || month > 12) return false;
    if (year < 1900 || year > DateTime.now().year) return false;

    return true;
  }
}
