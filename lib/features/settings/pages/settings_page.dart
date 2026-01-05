import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/data_management_service.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';
import '../../../shared/widgets/cards/menu_list_item.dart';
import '../../../shared/widgets/text/section_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _handleExport(BuildContext context) async {
    try {
      await DataManagementService.exportData();
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
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                centerTitle: false,
                backgroundColor: AppColors.darkBg,
                surfaceTintColor: AppColors.darkBg,
                title: Text(
                  'Settings',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeInSlide(
                      index: 0,
                      child: SectionHeader(title: 'DATA MANAGEMENT'),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      index: 1,
                      child: MenuListItem(
                        title: 'Export Data',
                        subtitle: 'Download your workout history',
                        icon: Icons.download_rounded,
                        color: AppColors.accent,
                        onTap: () => _handleExport(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      index: 2,
                      child: MenuListItem(
                        title: 'Import Data',
                        subtitle: 'Restore your history from file',
                        icon: Icons.upload_rounded,
                        color: AppColors.success,
                        onTap: () => _handleImport(context),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInSlide(
                      index: 3,
                      child: SectionHeader(title: 'DANGER ZONE'),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      index: 4,
                      child: MenuListItem(
                        title: 'Clear All Data',
                        subtitle: 'Permanently delete all records',
                        icon: Icons.delete_forever_rounded,
                        color: AppColors.error,
                        isDestructive: true,
                        onTap: () => _handleClearAll(context),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
