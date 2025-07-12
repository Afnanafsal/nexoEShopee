import 'package:flutter/material.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/size_config.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    _navigateToNextScreen();
  }

  _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(flex: 2),

            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/logo.png',
                width: getProportionateScreenWidth(120),
                height: getProportionateScreenWidth(120),
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: getProportionateScreenHeight(20)),

            // FishKart text with animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'FishKart',
                style: TextStyle(
                  fontFamily: 'Shadows Into Light Two',
                  fontSize: getProportionateScreenWidth(48),
                  fontWeight: FontWeight.bold,
                  color: Color(
                    0xFF4A6B7C,
                  ), // Dark teal/blue-grey color like the fish icon
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Spacer(flex: 2),

            Padding(
              padding: EdgeInsets.only(
                bottom: getProportionateScreenHeight(60),
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: getProportionateScreenHeight(16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
