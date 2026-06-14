import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/services/auth_service.dart';

class UserHomeScreen extends ConsumerWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background cybernetic gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  Color(0xFF0F172A),
                  Color(0xFF020617),
                ],
              ),
            ),
          ),
          
          // Radial Glow Circles (Aesthetics)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          // Logout Button - Minimalist Glassmorphic top-right
          Positioned(
            top: 50,
            right: 20,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.glassBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  tooltip: 'Keluar Akun',
                  onPressed: () async {
                    await ref.read(authServiceProvider).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ),

          // Main Center Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Shield Logo
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.05),
                      border: Border.all(
                        color: AppColors.primaryAccent.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 90,
                        color: AppColors.primaryAccent,
                      )
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .scaleXY(
                            begin: 0.95,
                            end: 1.05,
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          ),
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .shimmer(delay: 800.ms, duration: 1500.ms),

                  const SizedBox(height: 36),

                  // Brand Title
                  Text(
                    'LUCIFAX-CDM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryAccent.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 12),

                  // Subtitle & Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsing Green dot indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scaleXY(begin: 0.7, end: 1.3, duration: 800.ms)
                            .boxShadow(
                              begin: const BoxShadow(color: Colors.transparent),
                              end: const BoxShadow(color: AppColors.success, blurRadius: 6),
                            ),
                        const SizedBox(width: 10),
                        const Text(
                          'SISTEM PROTEKSI AKTIF',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 16),
                  
                  // Secondary informational tag
                  const Text(
                    'Perangkat Anda diproteksi oleh sistem keamanan anti-maling Lucifax.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
