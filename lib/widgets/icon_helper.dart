import 'package:flutter/material.dart';

class IconHelper extends StatelessWidget {
  final List<IconHelperItem> items;
  final double? fontSize;

  const IconHelper({super.key, required this.items, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;
    final effectiveFontSize = fontSize ?? (isVerySmall ? 10 : 12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 8 : 16,
        vertical: isVerySmall ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Wrap(
        spacing: isVerySmall ? 8 : 16,
        runSpacing: 4,
        children: items.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: isVerySmall ? 14 : 16,
                color: item.color ?? Colors.grey[700],
              ),
              const SizedBox(width: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: effectiveFontSize,
                  color: Colors.black54, 
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class IconHelperItem {
  final IconData icon;
  final String label;
  final Color? color;

  IconHelperItem({required this.icon, required this.label, this.color});
}
