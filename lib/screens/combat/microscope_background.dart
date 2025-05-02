import 'dart:math';
import 'package:flutter/material.dart';

/// A custom painter that creates a microscopic field background
class MicroscopeBackgroundPainter extends CustomPainter {
  final Color baseColor;
  final Color gridColor;
  final double gridOpacity;
  final bool showCircularView;
  
  MicroscopeBackgroundPainter({
    required this.baseColor,
    required this.gridColor,
    this.gridOpacity = 0.2,
    this.showCircularView = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height / 2);
    final radius = min(width, height) / 2;
    
    // Background fill
    final bgPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    
    if (showCircularView) {
      // Create microscope circular view effect with dark outer ring
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), 
                      Paint()..color = Colors.black);
      
      // Gradient for the circular microscope view
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            baseColor.withOpacity(1.0),
            baseColor.withOpacity(0.8),
            baseColor.withOpacity(0.6),
          ],
          stops: const [0.7, 0.85, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      
      canvas.drawCircle(center, radius, gradientPaint);
      
      // Outer ring of the microscope
      final ringPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;
      canvas.drawCircle(center, radius, ringPaint);
      
      // Inner light reflection effect
      final reflectionPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(center.dx * 0.7, center.dy * 0.7), radius: radius * 0.7),
        0,
        pi / 2,
        false,
        reflectionPaint,
      );
    } else {
      // Simple rectangular background
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);
    }
    
    // Draw microscope grid lines
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(gridOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Horizontal grid lines
    final gridSpacing = height / 20;
    for (var i = 0; i < 20; i++) {
      final y = i * gridSpacing;
      
      if (showCircularView) {
        // Clip the lines to be within the circle
        final path = Path();
        final halfWidth = sqrt(pow(radius, 2) - pow((y - center.dy).abs(), 2));
        
        if (!halfWidth.isNaN) {
          final startX = center.dx - halfWidth;
          final endX = center.dx + halfWidth;
          path.moveTo(startX, y);
          path.lineTo(endX, y);
          canvas.drawPath(path, gridPaint);
        }
      } else {
        canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
      }
    }
    
    // Vertical grid lines
    final verticalSpacing = width / 20;
    for (var i = 0; i < 20; i++) {
      final x = i * verticalSpacing;
      
      if (showCircularView) {
        final path = Path();
        final halfHeight = sqrt(pow(radius, 2) - pow((x - center.dx).abs(), 2));
        
        if (!halfHeight.isNaN) {
          final startY = center.dy - halfHeight;
          final endY = center.dy + halfHeight;
          path.moveTo(x, startY);
          path.lineTo(x, endY);
          canvas.drawPath(path, gridPaint);
        }
      } else {
        canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
      }
    }
    
    // Add random "cell" like blobs in the background
    final random = Random();
    final blobPaint = Paint()
      ..color = gridColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    for (var i = 0; i < 30; i++) {
      double x, y;
      
      if (showCircularView) {
        // Generate points within the circle
        final angle = random.nextDouble() * 2 * pi;
        final distance = random.nextDouble() * radius * 0.8; // Keep within 80% of radius
        x = center.dx + cos(angle) * distance;
        y = center.dy + sin(angle) * distance;
      } else {
        x = random.nextDouble() * width;
        y = random.nextDouble() * height;
      }
      
      final blobSize = 5 + random.nextDouble() * 15;
      canvas.drawCircle(Offset(x, y), blobSize, blobPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MicroscopeBackgroundPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.gridOpacity != gridOpacity ||
        oldDelegate.showCircularView != showCircularView;
  }
}

/// A background widget that creates a microscope view effect
class MicroscopeBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final bool showCircularView;
  
  const MicroscopeBackground({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFEBF8FF), // Light blue background
    this.showCircularView = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MicroscopeBackgroundPainter(
        baseColor: backgroundColor,
        gridColor: Colors.blue,
        showCircularView: showCircularView,
      ),
      child: child,
    );
  }
}
