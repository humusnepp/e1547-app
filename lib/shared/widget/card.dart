import 'package:flutter/material.dart';

class ColoredCard extends StatefulWidget {
  const ColoredCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.color,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.trailing,
    this.padding = const EdgeInsets.only(
      top: 4,
      bottom: 4,
      right: 10,
      left: stripeWidth + 6,
    ),
  });

  /// The content has to clear this width.
  static const double stripeWidth = 5;

  final Widget child;
  final Color? backgroundColor;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  bool get _interactive =>
      onTap != null || onLongPress != null || onSecondaryTap != null;

  @override
  State<ColoredCard> createState() => _ColoredCardState();
}

class _ColoredCardState extends State<ColoredCard> {
  bool _pressed = false;
  bool _held = false;
  int _pressToken = 0;

  void _press() {
    setState(() => _pressed = true);
    final token = ++_pressToken;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _pressToken == token && !_held) {
        setState(() => _pressed = false);
      }
    });
  }

  void _hold() {
    _held = true;
    setState(() => _pressed = true);
  }

  void _release() {
    _held = false;
    _press();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.backgroundColor ?? Theme.of(context).cardColor;
    final brightness = Theme.of(context).brightness;
    final pressedColor = Color.lerp(
      baseColor,
      brightness == Brightness.dark ? Colors.white : Colors.black,
      0.1,
    )!;

    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        color: _pressed ? pressedColor : baseColor,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Padding(padding: widget.padding, child: widget.child),
              ),
              if (widget.trailing case final trailing?) trailing,
            ],
          ),
          // Stacking gives the stripe the content's height rather than a
          // fixed one.
          if (widget.color case final stripeColor?)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: ColoredCard.stripeWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: stripeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget._interactive) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _press(),
        onTapCancel: () => setState(() => _pressed = false),
        onLongPress: widget.onLongPress,
        onLongPressDown: (_) => _hold(),
        onLongPressUp: _release,
        onLongPressCancel: _release,
        onSecondaryTap: widget.onSecondaryTap,
        onSecondaryTapDown: (_) => _press(),
        onSecondaryTapCancel: () => setState(() => _pressed = false),
        child: body,
      );
    }

    return Padding(padding: const EdgeInsets.all(2), child: body);
  }
}
