import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../model/dashboard_models.dart';
import '../widget/dashboard_view.dart';

class DashboardAnimationPage extends StatefulWidget {
  const DashboardAnimationPage({super.key});

  @override
  State<DashboardAnimationPage> createState() => _DashboardAnimationPageState();
}

class _DashboardAnimationPageState extends State<DashboardAnimationPage> {
  var progress = 0.1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('仪表盘动画')),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 100.h),
            DashboardView(
              data: DashboardDisplayData(
                amountText: '5000',
                progress: progress,
                progressColor: Colors.green,
                isCompleted: progress > 1,
              ),
              size: 220.h,
              tickLength: 30.w,
            ),
            SizedBox(height: 24.h),

            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  progress = Random().nextDouble();
                });
              },
              child: Container(
                height: 80.h,
                width: 200.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20.w),
                ),
                alignment: Alignment.center,
                child: Text("重启"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
