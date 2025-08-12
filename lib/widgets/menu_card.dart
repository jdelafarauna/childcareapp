import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool compact;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 12.0 : 16.0;
    final iconSize = compact ? 32.0 : 48.0;
    final fontSize = compact ? 13.0 : 15.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
