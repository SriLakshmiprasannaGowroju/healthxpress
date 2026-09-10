import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../user/user_main_nav.dart';
import '../doctor/doctor_main_nav.dart';
import '../store/store_main_nav.dart';
import '../store/store_onboarding_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  String _loadingStatus = 'Initializing HealthExpress AI...';
  bool _hasStartedPrecache = false;

  final List<String> _assetImagesToPrecache = [
    'assets/images/app_logo.png',
    'assets/images/google_logo.png',
    AppIllustrations.heroAiDoctor,
    AppIllustrations.rolePatient,
    AppIllustrations.roleDoctor,
    AppIllustrations.roleStore,
    AppIllustrations.otpSecurity,
    AppIllustrations.storeOnboarding,
    AppIllustrations.storePendingReview,
    AppIllustrations.storeDeliveryBike,
    AppIllustrations.aiTriageBot,
    AppIllustrations.emptyPrescriptions,
    AppIllustrations.teleconsultVideo,
    AppIllustrations.abdmHealthPass,
    AppIllustrations.emergencyAmbulance,
    AppIllustrations.orderSuccessBox,
  ];

  @override
  void initState() {
    super.initState();

    // 5-second dedicated loading progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      final val = _progressController.value;
      String newStatus;
      if (val < 0.25) {
        newStatus = '✨ Initializing HealthExpress AI Core...';
      } else if (val < 0.55) {
        newStatus = '🩺 Pre-caching 3D Avatars & Medical Assets...';
      } else if (val < 0.85) {
        newStatus = '🔒 Verifying ABDM & Healthcare Gateways...';
      } else {
        newStatus = '🚀 Launching Your Health Space...';
      }

      if (newStatus != _loadingStatus && mounted) {
        setState(() {
          _loadingStatus = newStatus;
        });
      }
    });

    _progressController.forward().then((_) {
      _checkAuthAndNavigate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStartedPrecache) {
      _hasStartedPrecache = true;
      _precacheAllAssets();
    }
  }

  Future<void> _precacheAllAssets() async {
    for (final assetPath in _assetImagesToPrecache) {
      try {
        await precacheImage(AssetImage(assetPath), context).catchError((_) {});
      } catch (_) {
        // Silently continue if an asset isn't ready
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    if (auth.isAuthenticated && auth.isOnboarded) {
      if (auth.currentRole == UserRole.doctor) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DoctorMainNav()),
        );
      } else if (auth.currentRole == UserRole.store) {
        final store = auth.currentStore;
        if (store.isVerified) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StoreMainNav()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StoreOnboardingScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserMainNav()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Ambient background glow circles
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing medical emblem with official HealthExpress logo
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 36,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 700.ms, curve: Curves.easeOutBack)
                      .then(delay: 200.ms)
                      .shimmer(duration: 1800.ms, color: Colors.blue.shade100),
                  const SizedBox(height: 28),
                  const Text(
                    'HealthExpress AI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'AI-Powered • Personalized • 24/7 Healthcare',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 11.2,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 42),

                  // 5-Second Animated Progress Bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, _) {
                      final progress = _progressAnimation.value;
                      final percent = (progress * 100).toInt();

                      return Column(
                        children: [
                          Container(
                            width: 240,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 240 * progress,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF60A5FA),
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Text(
                              _loadingStatus,
                              key: ValueKey(_loadingStatus),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Integrated with ABDM, Aarogyasri & Top Hospitals',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
