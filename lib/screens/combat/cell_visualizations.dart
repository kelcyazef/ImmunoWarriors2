import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/agent_pathogene.dart';
import '../../models/anticorps.dart';
import '../../models/combat_manager.dart';

/// A widget that visualizes combat units as cells under a microscope
class CellVisualization extends StatefulWidget {
  final CombatUnit unit;
  final bool isPlayerUnit;
  final bool isActive;
  final double size;
  
  const CellVisualization({
    super.key,
    required this.unit,
    required this.isPlayerUnit,
    this.isActive = false,
    this.size = 60,
  });

  @override
  State<CellVisualization> createState() => _CellVisualizationState();
}

class _CellVisualizationState extends State<CellVisualization> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(CellVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Health percentage to determine the opacity of the cell
    final healthPercentage = widget.unit.healthPoints / widget.unit.maxHealthPoints;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isActive ? _pulseAnimation.value : 1.0;
        
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: _buildCellRepresentation(healthPercentage),
    );
  }
  
  Widget _buildCellRepresentation(double healthPercentage) {
    // Determine the appropriate visual based on unit type
    if (widget.unit.isAnticorps) {
      return _buildAntibodyCell(healthPercentage);
    } else {
      final pathogen = widget.unit.unit as AgentPathogene;
      
      if (pathogen is Virus) {
        return _buildVirusCell(healthPercentage);
      } else if (pathogen is Bacterie) {
        return _buildBacteriaCell(healthPercentage);
      } else if (pathogen is Champignon) {
        return _buildFungusCell(healthPercentage);
      } else {
        return _buildGenericPathogen(healthPercentage);
      }
    }
  }
  
  /// Build a visualization for antibodies
  Widget _buildAntibodyCell(double healthPercentage) {
    final antibody = widget.unit.unit as Anticorps;
    final isOffensive = antibody is AnticorpsOffensif;
    
    // Different color schemes based on antibody type
    final baseColor = isOffensive 
        ? const Color(0xFF1E88E5) // Blue for offensive
        : const Color(0xFF43A047); // Green for defensive
    
    // Y-shaped antibody visualization 
    return Stack(
      children: [
        // Health indicator
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor.withOpacity(healthPercentage * 0.3),
          ),
        ),
        
        // Y-shaped antibody structure
        Center(
          child: CustomPaint(
            size: Size(widget.size * 0.8, widget.size * 0.8),
            painter: AntibodyCellPainter(
              color: baseColor,
              healthPercentage: healthPercentage,
              isOffensive: isOffensive,
            ),
          ),
        ),
        
        // Add a border that shows health
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: baseColor,
              width: 2 * healthPercentage,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build a visualization for virus pathogens
  Widget _buildVirusCell(double healthPercentage) {
    final baseColor = const Color(0xFFE53935); // Red for virus
    
    return Stack(
      children: [
        // Virus body
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor.withOpacity(healthPercentage * 0.4),
            border: Border.all(
              color: baseColor.withOpacity(healthPercentage * 0.8),
              width: 2,
            ),
          ),
        ),
        
        // Virus spikes
        Center(
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: VirusCellPainter(
              color: baseColor,
              healthPercentage: healthPercentage,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build a visualization for bacteria pathogens
  Widget _buildBacteriaCell(double healthPercentage) {
    final baseColor = const Color(0xFFF4511E); // Orange for bacteria
    
    return Stack(
      children: [
        // Bacteria elongated body
        Container(
          width: widget.size * 1.3,
          height: widget.size * 0.7,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(healthPercentage * 0.4),
            borderRadius: BorderRadius.circular(widget.size * 0.35),
            border: Border.all(
              color: baseColor.withOpacity(healthPercentage * 0.8),
              width: 2,
            ),
          ),
        ),
        
        // Flagella and internal structures
        Center(
          child: CustomPaint(
            size: Size(widget.size * 1.3, widget.size * 0.7),
            painter: BacteriaCellPainter(
              color: baseColor,
              healthPercentage: healthPercentage,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build a visualization for fungus pathogens
  Widget _buildFungusCell(double healthPercentage) {
    final baseColor = const Color(0xFF8E24AA); // Purple for fungus
    
    return Stack(
      children: [
        // Circular fungus cells clustered together
        Center(
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: FungusCellPainter(
              color: baseColor,
              healthPercentage: healthPercentage,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Generic pathogen visualization as fallback
  Widget _buildGenericPathogen(double healthPercentage) {
    final baseColor = const Color(0xFFD32F2F); // Red for generic pathogen
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: baseColor.withOpacity(healthPercentage * 0.5),
        border: Border.all(
          color: baseColor,
          width: 2 * healthPercentage,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.bug_report,
          color: Colors.white.withOpacity(healthPercentage * 0.9),
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

/// Painter for antibody cells with Y-shape structure
class AntibodyCellPainter extends CustomPainter {
  final Color color;
  final double healthPercentage;
  final bool isOffensive;
  
  AntibodyCellPainter({
    required this.color, 
    required this.healthPercentage,
    required this.isOffensive,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(healthPercentage * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * healthPercentage
      ..strokeCap = StrokeCap.round;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Draw Y-shaped antibody structure
    final path = Path();
    // Start at the bottom center
    path.moveTo(centerX, centerY + size.height * 0.4);
    // Draw up to center
    path.lineTo(centerX, centerY);
    // Draw top-left arm
    path.lineTo(centerX - size.width * 0.35, centerY - size.height * 0.35);
    // Move back to center
    path.moveTo(centerX, centerY);
    // Draw top-right arm
    path.lineTo(centerX + size.width * 0.35, centerY - size.height * 0.35);
    
    canvas.drawPath(path, paint);
    
    // Add internal details
    if (isOffensive) {
      // Add targeting circles for offensive antibodies
      final dotPaint = Paint()
        ..color = color.withOpacity(healthPercentage * 0.6)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(centerX - size.width * 0.35, centerY - size.height * 0.35), 
        4 * healthPercentage, 
        dotPaint
      );
      
      canvas.drawCircle(
        Offset(centerX + size.width * 0.35, centerY - size.height * 0.35), 
        4 * healthPercentage, 
        dotPaint
      );
    } else {
      // Add shield-like details for defensive antibodies
      final shieldPaint = Paint()
        ..color = color.withOpacity(healthPercentage * 0.3)
        ..style = PaintingStyle.fill;
      
      final shieldPath = Path();
      shieldPath.addOval(Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size.width * 0.5,
        height: size.height * 0.5,
      ));
      
      canvas.drawPath(shieldPath, shieldPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant AntibodyCellPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.healthPercentage != healthPercentage ||
           oldDelegate.isOffensive != isOffensive;
  }
}

/// Painter for virus cells with spikes
class VirusCellPainter extends CustomPainter {
  final Color color;
  final double healthPercentage;
  
  VirusCellPainter({
    required this.color, 
    required this.healthPercentage,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(healthPercentage * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * healthPercentage
      ..strokeCap = StrokeCap.round;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.4;
    
    // Draw virus spikes around the circumference
    final random = Random(1); // Fixed seed for consistent look
    final numSpikes = 12;
    
    for (var i = 0; i < numSpikes; i++) {
      final angle = (i / numSpikes) * 2 * pi;
      final spikeLength = radius * 0.4 * (0.8 + random.nextDouble() * 0.4);
      
      final innerX = centerX + radius * cos(angle);
      final innerY = centerY + radius * sin(angle);
      
      final outerX = centerX + (radius + spikeLength) * cos(angle);
      final outerY = centerY + (radius + spikeLength) * sin(angle);
      
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        paint,
      );
    }
    
    // Draw internal structure
    final innerPaint = Paint()
      ..color = color.withOpacity(healthPercentage * 0.3)
      ..style = PaintingStyle.fill;
    
    // Draw nucleic acid-like structures inside
    for (var i = 0; i < 3; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = radius * 0.6 * random.nextDouble();
      
      canvas.drawCircle(
        Offset(
          centerX + distance * cos(angle),
          centerY + distance * sin(angle),
        ),
        radius * 0.15,
        innerPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant VirusCellPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.healthPercentage != healthPercentage;
  }
}

/// Painter for bacteria cells with rod shape and flagella
class BacteriaCellPainter extends CustomPainter {
  final Color color;
  final double healthPercentage;
  
  BacteriaCellPainter({
    required this.color, 
    required this.healthPercentage,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(healthPercentage * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * healthPercentage
      ..strokeCap = StrokeCap.round;
    
    final fillPaint = Paint()
      ..color = color.withOpacity(healthPercentage * 0.2)
      ..style = PaintingStyle.fill;
    
    final width = size.width;
    final height = size.height;
    final random = Random(2); // Fixed seed for consistent look
    
    // Draw flagella
    final path = Path();
    
    // Left flagella (wavy line)
    path.moveTo(0, height / 2);
    
    final wavesLeft = 3;
    final waveAmplitude = height * 0.3;
    final segmentWidth = width * 0.25 / wavesLeft;
    
    for (var i = 0; i < wavesLeft; i++) {
      final x1 = segmentWidth * (i * 2 + 1) / (wavesLeft * 2);
      final y1 = height / 2 - waveAmplitude;
      
      final x2 = segmentWidth * (i * 2 + 2) / (wavesLeft * 2);
      final y2 = height / 2 + waveAmplitude;
      
      path.quadraticBezierTo(
        -width * 0.2 + x1, y1,
        -width * 0.2 + x2, y2,
      );
    }
    
    // Right flagella (wavy line)
    path.moveTo(width, height / 2);
    
    final wavesRight = 3;
    
    for (var i = 0; i < wavesRight; i++) {
      final x1 = segmentWidth * (i * 2 + 1) / (wavesRight * 2);
      final y1 = height / 2 - waveAmplitude;
      
      final x2 = segmentWidth * (i * 2 + 2) / (wavesRight * 2);
      final y2 = height / 2 + waveAmplitude;
      
      path.quadraticBezierTo(
        width + x1, y1,
        width + x2, y2,
      );
    }
    
    canvas.drawPath(path, paint);
    
    // Draw internal structures
    // Nucleoid-like structure
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.5, height * 0.5),
        width: width * 0.4,
        height: height * 0.4,
      ),
      fillPaint,
    );
    
    // Small plasmid-like circles
    for (var i = 0; i < 3; i++) {
      final x = width * (0.3 + random.nextDouble() * 0.4);
      final y = height * (0.3 + random.nextDouble() * 0.4);
      
      canvas.drawCircle(
        Offset(x, y),
        height * 0.05,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant BacteriaCellPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.healthPercentage != healthPercentage;
  }
}

/// Painter for fungus cells with budding yeast-like structures
class FungusCellPainter extends CustomPainter {
  final Color color;
  final double healthPercentage;
  
  FungusCellPainter({
    required this.color, 
    required this.healthPercentage,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(healthPercentage * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * healthPercentage;
    
    final fillPaint = Paint()
      ..color = color.withOpacity(healthPercentage * 0.3)
      ..style = PaintingStyle.fill;
    
    final width = size.width;
    final height = size.height;
    final random = Random(3); // Fixed seed for consistent look
    
    // Draw multiple budding cells clustered together
    final mainCellRadius = width * 0.35;
    
    // Main cell
    canvas.drawCircle(
      Offset(width * 0.4, height * 0.4),
      mainCellRadius,
      fillPaint,
    );
    
    canvas.drawCircle(
      Offset(width * 0.4, height * 0.4),
      mainCellRadius,
      paint,
    );
    
    // Budding cells
    final numberOfBuds = 4;
    
    for (var i = 0; i < numberOfBuds; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = mainCellRadius * 0.8;
      final budSize = mainCellRadius * (0.5 + random.nextDouble() * 0.3);
      
      final x = width * 0.4 + distance * cos(angle);
      final y = height * 0.4 + distance * sin(angle);
      
      canvas.drawCircle(
        Offset(x, y),
        budSize,
        fillPaint,
      );
      
      canvas.drawCircle(
        Offset(x, y),
        budSize,
        paint,
      );
      
      // Draw connection between cells
      canvas.drawLine(
        Offset(
          width * 0.4 + mainCellRadius * cos(angle) * 0.8,
          height * 0.4 + mainCellRadius * sin(angle) * 0.8,
        ),
        Offset(
          x - budSize * cos(angle) * 0.8,
          y - budSize * sin(angle) * 0.8,
        ),
        paint,
      );
    }
    
    // Internal structures
    for (var i = 0; i < 2; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = mainCellRadius * 0.5 * random.nextDouble();
      
      canvas.drawCircle(
        Offset(
          width * 0.4 + distance * cos(angle),
          height * 0.4 + distance * sin(angle),
        ),
        mainCellRadius * 0.15,
        Paint()..color = color.withOpacity(healthPercentage * 0.5),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant FungusCellPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.healthPercentage != healthPercentage;
  }
}

/// A widget that displays a health bar for a combat unit
class HealthBar extends StatelessWidget {
  final double healthPercentage;
  final Color color;
  final double width;
  final double height;
  
  const HealthBar({
    super.key,
    required this.healthPercentage,
    required this.color,
    this.width = 50,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: healthPercentage.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
