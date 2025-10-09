import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardChild = child;

    if (padding != null) {
      cardChild = Padding(
        padding: padding!,
        child: cardChild,
      );
    }

    Widget card = Card(
      margin: margin ?? const EdgeInsets.all(8.0),
      elevation: elevation ?? 4.0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: cardChild,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: card,
      );
    }

    return card;
  }
}