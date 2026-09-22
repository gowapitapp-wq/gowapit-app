import 'dart:ui';
import 'package:flutter/material.dart';
import '../design/tokens.dart';

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

/// Floating Navigation Dock ala Apple Frosted Sub-Nav (DESIGN.md)
/// Tanpa shadow kromo, menggunakan frosted parchment + hairline border, dan pill indicator aksen Pine.
class FloatingDock extends StatefulWidget {
  final List<DockItem> items;
  final int? selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final EdgeInsetsGeometry padding;

  const FloatingDock({
    super.key,
    required this.items,
    this.selectedIndex,
    this.onItemSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activePine = isDark ? AppTokens.actionPineDark : AppTokens.actionPine;
    final Color dockBg = isDark
        ? AppTokens.surfaceTile1.withValues(alpha: 0.88)
        : AppTokens.canvasParchment.withValues(alpha: 0.88);
    final Color hairline = isDark ? AppTokens.hairlineDark : AppTokens.hairlineLight;

    return SizedBox(
      height: 56,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: AppTokens.pill,
            border: Border.all(color: hairline, width: 1.0),
          ),
          child: ClipRRect(
            borderRadius: AppTokens.pill,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                color: dockBg,
                padding: widget.padding,
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
                        activeColor: activePine,
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
    );
  }
}

class _DockButton extends StatefulWidget {
  final DockItem item;
  final bool isSelected;
  final bool isHovered;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _DockButton({
    required this.item,
    required this.isSelected,
    required this.isHovered,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Micro-interaction scale 0.95 saat ditekan (DESIGN.md)
    final double scale = _isPressed ? 0.92 : 1.0;
    final Color inactiveColor = widget.isDark ? AppTokens.bodyMutedOnDark : AppTokens.inkMuted48;
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
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.activeColor.withValues(alpha: widget.isDark ? 0.20 : 0.12)
                  : Colors.transparent,
              borderRadius: AppTokens.pill,
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Icon(
              displayIcon,
              size: 22,
              color: widget.isSelected ? widget.activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
