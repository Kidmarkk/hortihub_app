import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;
    final double logoSize = isVerySmall ? 120 : 150;
    final double fontSize = isVerySmall ? 24 : 32;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF026D2A),
            Color(0xFF016325),
            Color(0xFF01581F),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/hortihub_logo_1.jpg',
              width: logoSize,
              height: logoSize,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported,
                color: Colors.white70,
                size: logoSize,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'MEG Horticulture Hub',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 40,
              height: 40,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}