import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../screens/analytics_screen.dart';
import '../screens/asset_inventory_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/spatial_home_screen.dart';

class BottomNavShell extends StatelessWidget {
  final AppState state;
  final SpatialPalette palette;

  const BottomNavShell({
    super.key,
    required this.state,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final screens = [
      SpatialHomeScreen(state: state, palette: palette),
      AssetInventoryScreen(state: state, palette: palette),
      AnalyticsScreen(state: state, palette: palette),
      ProfileSettingsScreen(state: state, palette: palette),
    ];

    final items = const [
      (Icons.view_in_ar_rounded, 'Home 3D'),
      (Icons.inventory_2_rounded, 'Inventaris'),
      (Icons.bar_chart_rounded, 'Analitik'),
      (Icons.tune_rounded, 'Profil'),
    ];

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        children: [
          IndexedStack(
            index: state.selectedTabIndex,
            children: screens,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: palette.glass,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: palette.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(items.length, (i) {
                        final selected = state.selectedTabIndex == i;
                        final item = items[i];
                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              state.setTab(i);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: selected
                                    ? palette.cyan.withOpacity(0.18)
                                    : Colors.transparent,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.$1,
                                    size: 20,
                                    color: selected
                                        ? palette.cyan
                                        : palette.textSecondary,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.$2,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? palette.cyan
                                          : palette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
