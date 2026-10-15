import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_tokens.dart';

/// Kerangka setelah login: background navy dengan glow, konten tab, dan
/// bottom nav kaca (Home, Schedule, [+], Progress, Profile).
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppSurfaces.background,
      extendBody: true,
      body: Stack(
        children: [
          const _Glow(top: -120, right: -100, size: 340,
              color: Color(0x8C5483B3)),
          const _Glow(top: 180, left: -140, size: 320,
              color: Color(0x426076FF)),
          const _Glow(top: 360, right: -60, size: 220,
              color: Color(0x1AFF966E)),
          const _Glow(bottom: -90, right: -70, size: 280,
              color: Color(0x4D7DA0CA)),

          SafeArea(bottom: false, child: navigationShell),
        ],
      ),

      bottomNavigationBar: _LumoBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        onFabTap: () => context.go('/home/new'),
      ),
    );
  }
}

/// Pill kaca blur berisi 4 ikon dan FAB gradient di tengah. Tab aktif
/// ditandai titik di bawah ikonnya.
class _LumoBottomNav extends StatelessWidget {
  const _LumoBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SizedBox(
          height: 92,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // FAB sengaja di luar ClipRRect supaya tidak terpotong saat
              // menyembul di atas bar.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(33),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      height: 66,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xE0051C38),
                        borderRadius: BorderRadius.circular(33),
                        border: Border.all(color: AppSurfaces.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF021024)
                                .withValues(alpha: 0.6),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NavIcon(
                            icon: Icons.home_rounded,
                            isActive: currentIndex == 0,
                            onTap: () => onTap(0),
                          ),
                          _NavIcon(
                            icon: Icons.calendar_month_rounded,
                            isActive: currentIndex == 1,
                            onTap: () => onTap(1),
                          ),
                          // Slot kosong untuk FAB.
                          const SizedBox(width: 56),
                          _NavIcon(
                            icon: Icons.bar_chart_rounded,
                            isActive: currentIndex == 2,
                            onTap: () => onTap(2),
                          ),
                          _NavIcon(
                            icon: Icons.person_outline_rounded,
                            isActive: currentIndex == 3,
                            onTap: () => onTap(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 36,
                child: GestureDetector(
                  onTap: onFabTap,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primarySubtle,
                      shape: BoxShape.circle,
                      boxShadow: [
                        ...AppShadows.fabGlow,
                        BoxShadow(
                          color:
                              AppColors.primary.withValues(alpha: 0.08),
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Color(0xFF021024),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ikon nav dengan titik indikator aktif menyala di bawahnya.
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.textSubtle,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: AppDurations.microAnimation,
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color:
                              AppColors.primary.withValues(alpha: 0.9),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lingkaran glow radial dekoratif.
class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double size;
  final Color color;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}
