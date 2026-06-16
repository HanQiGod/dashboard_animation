import 'package:flutter/material.dart';

class DashboardDisplayData {
  const DashboardDisplayData({
    this.title = '已消费',
    this.amountText = '500',
    this.progress = 0.7,
    this.progressColor = const Color(0xFFFF7A00),
    this.isCompleted = false,
  });

  final String title;
  final String amountText;
  final double progress;
  final Color progressColor;
  final bool isCompleted;
}
