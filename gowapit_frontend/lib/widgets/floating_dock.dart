import 'dart:ui';
import 'package:flutter/material.dart';

class DockItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final VoidCallback? onTap;

  const DockItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.onTap,
  });
}

class FloatingDock extends StatefulWidget {
  final List<DockItem> items;
  final int? selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final bool enableFloatingAnimation;
  final EdgeInsetsGeometry padding;

  const FloatingDock({
    super.key,
    required this.items,
    this.selectedIndex,
    this.onItemSelected,
    this.enableFloatingAnimation = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
  });

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _floatAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.enableFloatingAnimation) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    return SizedBox(
      height: 60, // Ketinggian terbatas agar tidak memenuhi layar
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          final double offsetY = widget.enableFloatingAnimation ? _floatAnimation.value : 0.0;
          return Transform.translate(
            offset: Offset(0, offsetY),
            child: child,
          );
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: 52, // Tinggi dock ramping pas dengan ukuran icon
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.40)
                      : const Color(0xFF9DC3C2).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF162524).withValues(alpha: 0.90)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFB3D89C).withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(widget.items.length, (index) {
                      final item = widget.items[index];
                      final bool isSelected = widget.selectedIndex == index;
                      final bool isHovered = _hoveredIndex == index;

                      return Expanded(
                        child: _DockButton(
                          item: item,
                          isSelected: isSelected,
                          isHovered: isHovered,
                          primaryColor: primaryColor,
                          isDark: isDark,
                          onTap: () {
                            widget.onItemSelected?.call(index);
                            item.onTap?.call();
                          },
                          onHover: (hovering) {
                            setState(() {
                              _hoveredIndex = hovering ? index : null;
                            });
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatefulWidget {
  final DockItem item;
  final bool isSelected;
  final bool isHovered;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _DockButton({
    required this.item,
    required this.isSelected,
    required this.isHovered,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed
        ? 0.90
        : (widget.isSelected || widget.isHovered)
            ? 1.12
            : 1.0;

    final Color activeColor = widget.primaryColor;
    final Color inactiveColor = widget.isDark ? Colors.white54 : const Color(0xFF717976);
    final IconData displayIcon = (widget.isSelected && widget.item.activeIcon != null)
        ? widget.item.activeIcon!
        : widget.item.icon;

    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? activeColor.withValues(alpha: widget.isDark ? 0.22 : 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(
              displayIcon,
              size: 24,
              color: widget.isSelected ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
