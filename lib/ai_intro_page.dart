import 'dart:math';
import 'package:flutter/material.dart';

// --- COLORS ---
const Color primaryColor = Color(0xFFD0E3FF);
const Color secondaryColor = Color(0xFFE9D5F8);
const Color incomeColor = Color(0xFF5A96F0);
const Color expenseColor = Color(0xFFB47BE8);
const Color progressFill = Color(0xFF5A96F0);

class AiIntroPage extends StatefulWidget {
  const AiIntroPage({super.key});

  @override
  State<AiIntroPage> createState() => _AiIntroPageState();
}

class _AiIntroPageState extends State<AiIntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // Continuous circular motion
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double radius = 10; // circle radius for floating motion

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double angle = _controller.value * 2 * pi;
              final double x = radius * cos(angle);
              final double y = radius * sin(angle);

              return Transform.translate(
                offset: Offset(x, y),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Circular logo area ---
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Center(
                        // You can replace this with your custom Flutter/AI icon
                        child: Icon(
                          Icons.auto_awesome, // or use Image.asset('assets/logo.png')
                          size: 60,
                          color: progressFill,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Your Financial Advisor",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: incomeColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
