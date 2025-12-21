import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';

/// Custom bottom navigation bar with wave-like flowing animation
class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sinkAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _riseAnimation;
  late Animation<double> _waveAnimation;
  
  int _displayedIndex = 0;
  int _targetIndex = 0;
  bool _isAnimating = false;

  // Nav items configuration
  static const List<_NavItemData> _items = [
    _NavItemData(Icons.shopping_cart_outlined, Icons.shopping_cart, AppStrings.shopping),
    _NavItemData(Icons.checklist_outlined, Icons.checklist, AppStrings.household),
    _NavItemData(Icons.restaurant_menu_outlined, Icons.restaurant_menu, AppStrings.food),
    _NavItemData(Icons.grass_outlined, Icons.grass, AppStrings.garden),
  ];

  @override
  void initState() {
    super.initState();
    _displayedIndex = widget.currentIndex;
    _targetIndex = widget.currentIndex;
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Phase 1: Sink down (0.0 - 0.25)
    _sinkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );
    
    // Phase 2: Slide horizontally (0.2 - 0.8)
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );
    
    // Phase 3: Rise up (0.75 - 1.0)
    _riseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Wave effect during slide
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _displayedIndex = _targetIndex;
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isAnimating) {
      _startAnimation(widget.currentIndex);
    }
  }
  
  void _startAnimation(int newIndex) {
    if (newIndex == _displayedIndex) return;
    
    setState(() {
      _targetIndex = newIndex;
      _isAnimating = true;
    });
    
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Convert tab index to X position
  double _getTabPosition(int index, double totalWidth) {
    const gapWidth = 56.0;
    final sideWidth = (totalWidth - gapWidth) / 2;
    final itemSpacing = sideWidth / 2;
    
    if (index < 2) {
      return itemSpacing * index + itemSpacing / 2;
    } else {
      final rightIndex = index - 2;
      return sideWidth + gapWidth + itemSpacing * rightIndex + itemSpacing / 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const indicatorWidth = 64.0;
              const indicatorHeight = 57.0;
              const navHeight = 64.0;

              return SizedBox(
                height: navHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Animated indicator with sink/slide/rise effect
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final fromPos = _getTabPosition(_displayedIndex, totalWidth);
                        final toPos = _getTabPosition(_targetIndex, totalWidth);
                        
                        // Calculate current horizontal position
                        final currentX = fromPos + (toPos - fromPos) * _slideAnimation.value;
                        
                        // Calculate vertical position (sink then rise)
                        double verticalOffset = 0;
                        double scaleY = 1.0;
                        double scaleX = 1.0;
                        double opacity = 1.0;
                        
                        if (_isAnimating) {
                          // Sink phase
                          if (_sinkAnimation.value < 1.0 && _riseAnimation.value == 0) {
                            verticalOffset = _sinkAnimation.value * (navHeight - 8);
                            scaleY = 1.0 - (_sinkAnimation.value * 0.7);
                            scaleX = 1.0 + (_sinkAnimation.value * 0.3);
                            opacity = 1.0 - (_sinkAnimation.value * 0.3);
                          }
                          // Sliding phase (at bottom)
                          else if (_slideAnimation.value > 0 && _slideAnimation.value < 1.0 && _riseAnimation.value < 0.5) {
                            verticalOffset = navHeight - 8;
                            scaleY = 0.3;
                            scaleX = 1.3 + (0.3 * _waveAnimation.value * (1 - _waveAnimation.value) * 4);
                            opacity = 0.7;
                          }
                          // Rise phase
                          if (_riseAnimation.value > 0) {
                            verticalOffset = (navHeight - 8) * (1.0 - _riseAnimation.value);
                            scaleY = 0.3 + (_riseAnimation.value * 0.7);
                            scaleX = 1.3 - (_riseAnimation.value * 0.3);
                            opacity = 0.7 + (_riseAnimation.value * 0.3);
                          }
                        }
                        
                        return Positioned(
                          left: currentX - indicatorWidth / 2,
                          top: 6 + verticalOffset,
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.identity()
                              ..scale(scaleX, scaleY),
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: indicatorWidth,
                                height: indicatorHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primaryPurple.withOpacity(0.2),
                                      AppColors.primaryPurple.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                  border: Border.all(
                                    color: AppColors.primaryPurple.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurple.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Wave trail effect during animation
                    if (_isAnimating)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          if (_slideAnimation.value <= 0 || _slideAnimation.value >= 1) {
                            return const SizedBox.shrink();
                          }
                          
                          final fromPos = _getTabPosition(_displayedIndex, totalWidth);
                          final toPos = _getTabPosition(_targetIndex, totalWidth);
                          
                          return Stack(
                            children: List.generate(3, (i) {
                              final delay = i * 0.15;
                              final progress = (_slideAnimation.value - delay).clamp(0.0, 1.0);
                              final trailX = fromPos + (toPos - fromPos) * progress;
                              final trailOpacity = (0.3 - (i * 0.1)) * (1 - _slideAnimation.value);
                              
                              return Positioned(
                                left: trailX - 20,
                                bottom: 4,
                                child: Opacity(
                                  opacity: trailOpacity.clamp(0.0, 1.0),
                                  child: Container(
                                    width: 40,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryPurple,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    
                    // Navigation items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0),
                        _buildNavItem(1),
                        const SizedBox(width: 56),
                        _buildNavItem(2),
                        _buildNavItem(3),
                      ],
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

  Widget _buildNavItem(int index) {
    final item = _items[index];
    final isActive = widget.currentIndex == index;
    
    return _NavItem(
      icon: item.icon,
      activeIcon: item.activeIcon,
      label: item.label,
      isActive: isActive,
      onTap: () => widget.onTap(index),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  
  const _NavItemData(this.icon, this.activeIcon, this.label);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isActive ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -value * 2),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: Color.lerp(
                      AppColors.gray,
                      AppColors.primaryPurple,
                      value,
                    ),
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isActive ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.lerp(
                      FontWeight.w400,
                      FontWeight.w600,
                      value,
                    ),
                    color: Color.lerp(
                      AppColors.gray,
                      AppColors.primaryPurple,
                      value,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
