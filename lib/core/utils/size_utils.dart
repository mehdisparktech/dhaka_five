import 'package:flutter/widgets.dart';

extension SizeUtils on BuildContext {
  double get w => MediaQuery.of(this).size.width;
  double get h => MediaQuery.of(this).size.height;
}
