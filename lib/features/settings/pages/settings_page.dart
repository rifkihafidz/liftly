import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/data_management_service.dart';
import '../../../shared/widgets/app_dialogs.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _handleExport(BuildContext context) async {
    try {
      await DataManagementService.exportData();

      // Note: Share sheet will open, so we don't necessarily need a success snackbar
      // as the user sees the file. But a confirmation is nice.
    } catch (e) {
      if (context.mounted) {
        await AppDialogs.showErrorDialog(
          context: context,
          title: 'Export Failed',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    try {
      final result = await AppDialogs.showConfirmationDialog(
        context: context,
        title: 'Import Data',
        message:
            'Importing data will replace existing records with the same IDs. Are you sure you want to continue?',
        confirmText: 'Import',
        isDangerous: false,
      );

      if (result != true) return;

      if (!context.mounted) return;

      final importResult = await DataManagementService.importData();

      if (context.mounted) {
        if (importResult == 'Import cancelled') {
          // No action needed
        } else {
          await AppDialogs.showSuccessDialog(
            context: context,
            title: 'Import Successful',
            message: importResult,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        await AppDialogs.showErrorDialog(
          context: context,
          title: 'Import Failed',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _handleClearAll(BuildContext context) async {
    final confirmed = await AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Clear All Data',
      message:
          'This will permanently delete all your workouts and plans. This action cannot be undone.',
      confirmText: 'Clear Everything',
      isDangerous: true,
    );

    if (confirmed != true) return;

    try {
      if (!context.mounted) return;

      await DataManagementService.clearAllData();

      if (context.mounted) {
        await AppDialogs.showSuccessDialog(
          context: context,
          title: 'Success',
          message: 'All data cleared successfully',
        );
      }
    } catch (e) {
      if (context.mounted) {
        await AppDialogs.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Failed to clear data: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Export Data',
                subtitle: 'Download your workout history as an Excel file',
                icon: Icons.download,
                color: AppColors.accent,
                onTap: () => _handleExport(context),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Import Data',
                subtitle: 'Restore your history from an Excel file',
                icon: Icons.upload,
                color: AppColors.success,
                onTap: () => _handleImport(context),
              ),
              const SizedBox(height: 32),
              Text(
                'Troubleshooting',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Clear All Data',
                subtitle: 'Remove all workouts and plans permanently',
                icon: Icons.delete_forever,
                color: AppColors.error,
                onTap: () => _handleClearAll(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
