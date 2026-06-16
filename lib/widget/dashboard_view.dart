import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../model/dashboard_models.dart';

/// 仪表盘 view
class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.data,
    this.size,
    this.tickLength = 24,
  });

  final DashboardDisplayData data;
  final double? size;
  final double tickLength;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressCurve;
  double _animationBegin = 0;
  double _animationEnd = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressCurve = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _animationEnd = widget.data.progress.clamp(0.0, 1.0);
    if (_animationEnd > 0) {
      _progressController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final double nextProgress = widget.data.progress.clamp(0.0, 1.0);
    if ((nextProgress - _animationEnd).abs() < 0.0001) {
      return;
    }
    _animationBegin = _currentAnimatedProgress;
    _animationEnd = nextProgress;
    if ((_animationBegin - _animationEnd).abs() < 0.0001) {
      _progressController.value = 1;
      return;
    }
    _progressController
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DashboardDisplayData displayData = widget.data;
    final double gaugeSize = widget.size ?? 520.w;
    final Color resolvedProgressColor = displayData.isCompleted
        ? const Color(0xFF16A425)
        : displayData.progressColor;
    final double resolvedRingWidth = 16.w;
    final double resolvedTickWidth = 3.w;
    final double resolvedGlowRadius = gaugeSize * 0.34;
    final double resolvedTickLength = widget.tickLength.w;

    return Container(
      width: gaugeSize,
      height: gaugeSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(500.r),
        boxShadow: [
          BoxShadow(
            color: Color(0xff000000).withValues(alpha: .04),
            blurRadius: 16.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _progressCurve,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(gaugeSize),
                  painter: _DashboardStaticPainter(
                    ringWidth: resolvedRingWidth,
                    tickWidth: resolvedTickWidth,
                    glowRadius: resolvedGlowRadius,
                    tickLength: resolvedTickLength,
                    progressColor: resolvedProgressColor,
                    isCompleted: displayData.isCompleted,
                  ),
                ),
              ),
              builder: (
                BuildContext context,
                Widget? child,
              ) {
                final double animatedProgress = _currentAnimatedProgress;
                return CustomPaint(
                  size: Size.square(gaugeSize),
                  foregroundPainter: _DashboardProgressPainter(
                    progress: animatedProgress,
                    ringWidth: resolvedRingWidth,
                    progressColor: resolvedProgressColor,
                    isCompleted: displayData.isCompleted,
                    tickLength: resolvedTickLength,
                  ),
                  child: child,
                );
              },
            ),
          ),
          RepaintBoundary(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  displayData.title,
                  style: TextStyle(
                    color: Color(0xff3D3D3D),
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  displayData.amountText,
                  style: TextStyle(
                    color: resolvedProgressColor,
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get _currentAnimatedProgress {
    return lerpDouble(_animationBegin, _animationEnd, _progressCurve.value) ??
        _animationEnd;
  }
}

class _DashboardStaticPainter extends CustomPainter {
  const _DashboardStaticPainter({
    required this.ringWidth,
    required this.tickWidth,
    required this.glowRadius,
    required this.tickLength,
    required this.progressColor,
    required this.isCompleted,
  });

  final double ringWidth;
  final double tickWidth;
  final double glowRadius;
  final double tickLength;
  final Color progressColor;
  final bool isCompleted;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerBoundaryRadius = size.width / 2;
    final double progressRadius =
        outerBoundaryRadius - tickLength - ringWidth / 2;
    final Rect arcRect = Rect.fromCircle(
      center: center,
      radius: progressRadius,
    );
    final double innerRingWidth = 2.w;
    final double innerRingRadius =
        progressRadius - ringWidth / 2 - tickLength - innerRingWidth / 2;

    _paintTicks(canvas, center, progressRadius, outerBoundaryRadius);
    _paintGlow(canvas, center, progressRadius);
    _paintInnerRing(
      canvas,
      center,
      innerRingRadius,
      innerRingWidth,
    );

    final Paint baseArcPaint = Paint()
      ..color = Color(0xffE2E4EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      arcRect,
      _DashboardGeometry.startAngle,
      _DashboardGeometry.totalSweep,
      false,
      baseArcPaint,
    );
  }

  void _paintTicks(
    Canvas canvas,
    Offset center,
    double progressRadius,
    double outerBoundaryRadius,
  ) {
    final Paint tickPaint = Paint()
      ..color = const Color(0xFFE9ECF2)
      ..strokeWidth = tickWidth
      ..strokeCap = StrokeCap.round;
    const int tickCount = 7;
    final double tickStartRadius = progressRadius + ringWidth / 2;
    final double tickEndRadius = outerBoundaryRadius;

    for (int index = 0; index < tickCount; index++) {
      final double angle = _DashboardGeometry.startAngle +
          _DashboardGeometry.totalSweep * index / (tickCount - 1);
      final Offset start = Offset(
        center.dx + tickStartRadius * math.cos(angle),
        center.dy + tickStartRadius * math.sin(angle),
      );
      final Offset end = Offset(
        center.dx + tickEndRadius * math.cos(angle),
        center.dy + tickEndRadius * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  void _paintGlow(Canvas canvas, Offset center, double radius) {
    final Rect glowRect = Rect.fromCircle(center: center, radius: glowRadius);
    final Paint innerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          progressColor.withValues(alpha: 0.10),
          progressColor.withValues(alpha: isCompleted ? 0.05 : 0.07),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(glowRect);

    final Paint ringGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          progressColor.withValues(alpha: 0.08),
          progressColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const <double>[0.62, 0.84, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.18))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, glowRadius, innerGlowPaint);
    canvas.drawCircle(center, radius * 1.08, ringGlowPaint);
  }

  void _paintInnerRing(
    Canvas canvas,
    Offset center,
    double innerRingRadius,
    double innerRingWidth,
  ) {
    final Paint innerRingPaint = Paint()
      ..color = progressColor.withValues(alpha: isCompleted ? 0.18 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerRingWidth;
    canvas.drawCircle(center, innerRingRadius, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _DashboardStaticPainter oldDelegate) {
    return oldDelegate.ringWidth != ringWidth ||
        oldDelegate.tickWidth != tickWidth ||
        oldDelegate.glowRadius != glowRadius ||
        oldDelegate.tickLength != tickLength ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.isCompleted != isCompleted;
  }
}

class _DashboardProgressPainter extends CustomPainter {
  const _DashboardProgressPainter({
    required this.progress,
    required this.ringWidth,
    required this.progressColor,
    required this.isCompleted,
    required this.tickLength,
  });

  final double progress;
  final double ringWidth;
  final Color progressColor;
  final bool isCompleted;
  final double tickLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerBoundaryRadius = size.width / 2;
    final double progressRadius =
        outerBoundaryRadius - tickLength - ringWidth / 2;
    final Rect arcRect = Rect.fromCircle(
      center: center,
      radius: progressRadius,
    );
    final double progressSweep = _DashboardGeometry.totalSweep * progress;

    final Paint progressArcPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          progressColor,
          _mixWithWhite(progressColor, isCompleted ? 0.08 : 0.18),
        ],
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      arcRect,
      _DashboardGeometry.startAngle,
      progressSweep,
      false,
      progressArcPaint,
    );

    final double thumbAngle = _DashboardGeometry.startAngle + progressSweep;
    final Offset thumbCenter = Offset(
      center.dx + progressRadius * math.cos(thumbAngle),
      center.dy + progressRadius * math.sin(thumbAngle),
    );

    final Paint thumbShadowPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(thumbCenter, ringWidth * 0.82, thumbShadowPaint);

    final Paint thumbOuterPaint = Paint()..color = progressColor;
    final Paint thumbInnerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(thumbCenter, ringWidth * 0.72, thumbOuterPaint);
    canvas.drawCircle(thumbCenter, ringWidth * 0.28, thumbInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _DashboardProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringWidth != ringWidth ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.tickLength != tickLength;
  }
}

class _DashboardGeometry {
  static const double startAngle = math.pi * 0.75;
  static const double totalSweep = math.pi * 1.5;
}

Color _mixWithWhite(Color color, double amount) {
  return Color.lerp(color, Colors.white, amount) ?? color;
}
