import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _blueBlobAnimation;
  late Animation<Offset> _orangeBlobAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true); // Repeat the animation for continuous effect

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _blueBlobAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, 0.04),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _orangeBlobAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0.04, -0.04),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _animation,
        child: Stack(
          children: [
            // Animated Positioned blue blob
            Positioned(
              top: 120,
              right: 60,
              child: SlideTransition(
                position: _blueBlobAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SvgPicture.asset(
                    'assets/images/blue-blob.svg',
                    width: 130,
                  ),
                ),
              ),
            ),
            // Animated Positioned orange blob
            Positioned(
              top: 700,
              left: 0,
              child: SlideTransition(
                position: _orangeBlobAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SvgPicture.asset(
                    'assets/images/orange-blob.svg',
                    width: 60,
                  ),
                ),
              ),
            ),
            // FadeTransition for the text content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'elea',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Tagline at the bottom of the screen
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Text(
                  'Tagline goes here',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
