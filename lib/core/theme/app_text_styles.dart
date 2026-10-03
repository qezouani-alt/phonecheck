import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const largeTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.8,
  );
  static const section = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const cardTitle = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 15, height: 1.42);
  static const secondary = TextStyle(fontSize: 13, height: 1.4);
}
