import 'package:flutter/material.dart';

class AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // 绘制背景
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      paint,
    );

    // 绘制字符串符号
    paint.color = Colors.white;
    final path = Path();
    
    // 绘制 "S" 形状
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.3, h * 0.3);
    path.cubicTo(
      w * 0.7, h * 0.2,
      w * 0.3, h * 0.5,
      w * 0.7, h * 0.7,
    );
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.08;
    paint.strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // 绘制引号
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 1;
    canvas.drawCircle(
      Offset(w * 0.25, h * 0.25),
      size.width * 0.06,
      paint,
    );
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.75),
      size.width * 0.06,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 