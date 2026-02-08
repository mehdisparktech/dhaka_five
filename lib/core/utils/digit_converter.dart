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

  /// লিঙ্গ (Gender) ইংরেজি থেকে বাংলায় রূপান্তর
  /// "Male" → "পুরুষ", "Female" → "মহিলা", "M" → "পুরুষ", "F" → "মহিলা"
  static String genderToBangla(String input) {
    if (input.isEmpty || input == '-') return input;

    final trimmed = input.trim();
    final upper = trimmed.toUpperCase();

    // ইংরেজি লিঙ্গ মানগুলো বাংলায় রূপান্তর
    switch (upper) {
      case 'MALE':
      case 'M':
        return 'পুরুষ';
      case 'FEMALE':
      case 'F':
        return 'মহিলা';
      default:
        // যদি ইতিমধ্যে বাংলায় থাকে বা অন্য কোনো মান হয়, শুধু সংখ্যাগুলো কনভার্ট করি
        return enToBn(trimmed);
    }
  }

  /// লিঙ্গ (Gender) বাংলা থেকে ইংরেজিতে রূপান্তর
  /// "পুরুষ" → "Male", "মহিলা" → "Female"
  static String genderToEnglish(String input) {
    if (input.isEmpty || input == '-') return input;

    final trimmed = input.trim();

    // বাংলা লিঙ্গ মানগুলো ইংরেজিতে রূপান্তর
    if (trimmed == 'পুরুষ') {
      return 'male';
    } else if (trimmed == 'মহিলা') {
      return 'female';
    }

    // যদি ইতিমধ্যে ইংরেজিতে থাকে, সেটাই রিটার্ন করি
    return trimmed;
  }
}
