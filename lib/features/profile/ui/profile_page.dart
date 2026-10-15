import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/lumo_mark.dart';
import '../../auth/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../settings/providers/settings_providers.dart';

/// Halaman profil: avatar, statistik, pengaturan, dan logout.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  /// Bottom sheet untuk memilih daily goal (1 sampai 10).
  Future<void> _pickDailyGoal(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppSurfaces.scrim,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppSurfaces.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          // Harus uniform, Flutter menolak border non-uniform + borderRadius.
          border: Border.fromBorderSide(
            BorderSide(color: AppSurfaces.cardBorderHover),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSubtle.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Daily goal',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Berapa task yang ingin diselesaikan per hari?',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 1; i <= 10; i++)
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, i),
                    child: Container(
                      width: 48,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: i == current
                            ? AppGradients.primarySubtle
                            : null,
                        color: i == current ? null : AppSurfaces.glass,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: i == current
                              ? AppColors.primary.withValues(alpha: 0.9)
                              : AppSurfaces.cardBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$i',
                          style: Theme.of(ctx)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: i == current
                                    ? const Color(0xFF021024)
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setDailyGoal(picked);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Keluar?'),
            content:
                const Text('Anda harus login kembali untuk mengakses task.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final email = ref.watch(
      authControllerProvider.select((s) => s.user?.email),
    );
    final name = email?.split('@').first ?? 'User';
    final capitalizedName = name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : name;
    final initials = capitalizedName.length >= 2
        ? capitalizedName.substring(0, 2).toUpperCase()
        : capitalizedName.toUpperCase();

    final settings = ref.watch(settingsProvider);
    final stats = ref.watch(dashboardProvider).value;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
      children: [
        Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 20),

        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5483B3), Color(0xFFC1E8FF)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF021024),
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Center(
          child: Text(
            capitalizedName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            email ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 22),

        Row(
          children: [
            _StatTile(value: '${stats?.streak ?? 0}', label: 'streak'),
            const SizedBox(width: 10),
            _StatTile(value: '${stats?.done ?? 0}', label: 'done'),
            const SizedBox(width: 10),
            _StatTile(
              value: '${stats?.byCategory.length ?? 0}',
              label: 'categories',
            ),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: AppSurfaces.glass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppSurfaces.cardBorder),
          ),
          child: Column(
            children: [
              _SettingRow(
                title: 'Notifications',
                trailing: Switch.adaptive(
                  value: settings.notificationsEnabled,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setNotifications(v),
                  activeThumbColor: AppColors.tertiary,
                ),
                showDivider: true,
              ),
              _SettingRow(
                title: 'Daily goal',
                onTap: () =>
                    _pickDailyGoal(context, ref, settings.dailyGoal),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${settings.dailyGoal} tasks',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.textSubtle),
                  ],
                ),
                showDivider: true,
              ),
              // App cuma dark mode, jadi appearance hanya ditampilkan.
              _SettingRow(
                title: 'Appearance',
                trailing: Text(
                  'Dark',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                showDivider: true,
              ),
              _SettingRow(
                title: 'About TaskFlow',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'TaskFlow',
                  applicationVersion: '1.0.0',
                  applicationIcon: const LumoMarkTile(size: 44, glow: false),
                  children: [
                    Text(
                      'The calm way to get coursework done.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.textSubtle),
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: () => _logout(context, ref),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                'Log out',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppSurfaces.glass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppSurfaces.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.trailing,
    required this.showDivider,
    this.onTap,
  });
  final String title;
  final Widget trailing;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                  ),
                ),
                trailing,
              ],
            ),
          ),
          if (showDivider)
            const Divider(
              height: 1,
              color: AppSurfaces.cardBorder,
              indent: 16,
              endIndent: 16,
            ),
        ],
      ),
    );
  }
}
