import 'dart:math';
import 'package:flutter/material.dart';
import 'ai_intro_info_page.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    // --- Circular motion controller ---
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // --- Fade controller ---
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // --- Delayed fade + navigation (1.5s) ---
    Future.delayed(const Duration(milliseconds: 1500), () async {
      await _fadeController.forward();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AiIntroInfoPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double innerRadius = 25; // movement radius inside the circle

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
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.0).animate(_fadeController),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Outer Circle with moving robot ---
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _orbitController,
                    builder: (context, child) {
                      final angle = _orbitController.value * 2 * pi;
                      final offset = Offset(
                        innerRadius * cos(angle),
                        innerRadius * sin(angle),
                      );
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // ✅ Robot icon moves inside the circle
                          Transform.translate(
                            offset: offset,
                            child: const Icon(
                              Icons.smart_toy_rounded,
                              size: 60,
                              color: progressFill,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // --- Title text ---
                const Text(
                  "Your Financial Advisor",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: incomeColor,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
