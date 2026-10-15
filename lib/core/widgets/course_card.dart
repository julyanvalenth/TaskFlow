import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Kartu kategori di rail horizontal Home: dot warna, nama, sisa task, dan
/// progress.
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.name,
    required this.tasksLeft,
    required this.progressPercent,
    required this.colorDef,
    this.onTap,
  });

  final String name;
  final int tasksLeft;
  final int progressPercent;
  final CategoryColorDef colorDef;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = progressPercent.clamp(0, 100);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 164,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.2, -0.5),
            end: const Alignment(1.0, 1.0),
            colors: [
              colorDef.tint,
              const Color(0xEB041832),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppSurfaces.cardBorderHover),
          boxShadow: [
            BoxShadow(
              color: colorDef.glow,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorDef.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // Flexible supaya nama menyusut ke 1 baris + ellipsis kalau tinggi
            // rail tidak cukup untuk 2 baris.
            Flexible(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$tasksLeft tasks left',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: AppSurfaces.glass,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorDef.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '$pct%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
