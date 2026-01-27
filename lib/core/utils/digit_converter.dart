class DigitConverter {
  /// বাংলা ডিজিট → ইংরেজি ডিজিট (ভ্যালিডেশনের জন্য)
  static String bnToEn(String input) {
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    for (int i = 0; i < bn.length; i++) {
      input = input.replaceAll(bn[i], en[i]);
    }
    return input;
  }

  /// ইংরেজি ডিজিট → বাংলা ডিজিট (API তে সব ডাটা বাংলায় পাঠানোর জন্য)
  static String enToBn(String input) {
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    for (int i = 0; i < en.length; i++) {
      input = input.replaceAll(en[i], bn[i]);
    }
    return input;
  }
}
