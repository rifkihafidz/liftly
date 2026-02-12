import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/data_management_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';
import '../../../shared/widgets/cards/menu_list_item.dart';
import '../../../shared/widgets/text/section_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  GoogleSignInAccount? _currentUser;
  bool _isAutoBackupEnabled = false;
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initBackupState();
  }

  Future<void> _initBackupState() async {
    final backupService = BackupService();
    await backupService.init();

    final autoBackup = await HiveService.getPreference('auto_backup_enabled');

    if (mounted) {
      setState(() {
        _currentUser = backupService.currentUser;
        _isAutoBackupEnabled = autoBackup == 'true';
        _isInitializing = false;
      });
    }
  }

  Future<void> _handleGoogleConnect() async {
    setState(() => _isLoading = true);
    try {
      final user = await BackupService().signIn();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(
          context: context,
          title: 'Connection Failed',
          message:
              'Could not sign in to Google Drive. Please ensure configuration is correct.\n\nError: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleDisconnect() async {
    await BackupService().signOut();
    if (mounted) {
      setState(() {
        _currentUser = null;
      });
    }
  }

  Future<void> _handleBackupNow() async {
    AppDialogs.showLoadingDialog(context, 'Backing up your data...');
    try {
      await BackupService().backupDatabase();
      if (mounted) {
        AppDialogs.hideLoadingDialog(context);
        AppDialogs.showSuccessDialog(
          context: context,
          title: 'Backup Successful',
          message:
              'Your data has been safely backed up (Liftly Backup folder).',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.hideLoadingDialog(context);
        AppDialogs.showErrorDialog(
          context: context,
          title: 'Backup Failed',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _handleToggleAutoBackup(bool value) async {
    if (value && _currentUser == null) {
      await _handleGoogleConnect();
      if (_currentUser == null) return; // Failed to connect
    }

    await HiveService.savePreference('auto_backup_enabled', value.toString());
    setState(() {
      _isAutoBackupEnabled = value;
    });
  }

  Future<void> _handleExport(BuildContext context) async {
    AppDialogs.showLoadingDialog(context, 'Exporting to Excel...');
    try {
      await DataManagementService.exportData();
      if (context.mounted) AppDialogs.hideLoadingDialog(context);
    } catch (e) {
      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context);
        await AppDialogs.showErrorDialog(
          context: context,
          title: 'Export Failed',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      final backups = await BackupService().listBackups();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (backups.isEmpty) {
        AppDialogs.showErrorDialog(
          context: context,
          title: 'No Backups Found',
          message:
              'Could not find any backups in your Google Drive (Liftly Backup folder).',
        );
        return;
      }

      // Show selection dialog
      final selectedFileId = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text(
            'Select Backup',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final file = backups[index];
                final date = file.createdTime != null
                    ? DateFormat('dd MMM yyyy, HH:mm').format(file.createdTime!)
                    : 'Unknown date';

                return ListTile(
                  title: Text(
                    file.name ?? 'Unknown',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    date,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: AppColors.accent,
                  ),
                  onTap: () => Navigator.pop(context, file.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedFileId != null) {
        if (!mounted) return;

        final confirmed = await AppDialogs.showConfirmationDialog(
          context: context,
          title: 'Restore Backup',
          message:
              'This will replace current records with data from this backup. Are you sure?',
          confirmText: 'Restore Now',
          isDangerous: true,
        );

        if (confirmed == true) {
          if (!mounted) return;
          AppDialogs.showLoadingDialog(context, 'Restoring data from Cloud...');

          await BackupService().restoreDatabase(selectedFileId);

          if (!mounted) return;
          AppDialogs.hideLoadingDialog(context);
          AppDialogs.showSuccessDialog(
            context: context,
            title: 'Restore Successful',
            message: 'Application will now reload with new data.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) setState(() => _isLoading = false);
        // Ensure any loading dialog is hidden
        try {
          AppDialogs.hideLoadingDialog(context);
        } catch (_) {}

        AppDialogs.showErrorDialog(
          context: context,
          title: 'Restore Failed',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
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

      AppDialogs.showLoadingDialog(context, 'Importing data from file...');
      final importResult = await DataManagementService.importData();

      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context);
        if (importResult != 'Import cancelled') {
          await AppDialogs.showSuccessDialog(
            context: context,
            title: 'Import Successful',
            message: importResult,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context);
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

    if (!context.mounted) return;
    AppDialogs.showLoadingDialog(context, 'Clearing all data...');
    try {
      if (!context.mounted) return;
      await DataManagementService.clearAllData();
      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context);
        await AppDialogs.showSuccessDialog(
          context: context,
          title: 'Success',
          message: 'All data cleared successfully',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context);
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
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(color: AppColors.accent),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeInSlide(
                      index: 0,
                      child: SectionHeader(title: 'CLOUD BACKUP'),
                    ),
                    const SizedBox(height: 16),
                    if (_isInitializing)
                      FadeInSlide(
                        index: 1,
                        child: MenuListItem(
                          title: 'Checking Status',
                          subtitle: 'Verifying Google Account...',
                          icon: Icons.sync,
                          color: AppColors.textSecondary,
                          onTap: () {},
                          isLoading: true,
                        ),
                      )
                    else if (_currentUser == null)
                      FadeInSlide(
                        index: 1,
                        child: MenuListItem(
                          title: 'Connect Google Drive',
                          subtitle: 'Enable sync across your devices',
                          icon: Icons.cloud_outlined,
                          color: AppColors.accent,
                          onTap: _handleGoogleConnect,
                          isLoading: _isLoading,
                        ),
                      )
                    else ...[
                      FadeInSlide(
                        index: 1,
                        child: MenuListItem(
                          title: 'Google Account',
                          subtitle: _currentUser?.email ?? 'Connected',
                          icon: Icons.account_circle_outlined,
                          color: AppColors.accent,
                          onTap: () {},
                          trailing: TextButton(
                            onPressed: _handleGoogleDisconnect,
                            child: const Text('Logout'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInSlide(
                        index: 2,
                        child: MenuListItem(
                          title: 'Auto-Backup Workout',
                          subtitle: 'Upload data after each session',
                          icon: Icons.auto_mode_rounded,
                          color: AppColors.success,
                          onTap: () =>
                              _handleToggleAutoBackup(!_isAutoBackupEnabled),
                          trailing: Switch(
                            value: _isAutoBackupEnabled,
                            onChanged: _handleToggleAutoBackup,
                            activeTrackColor: AppColors.accent,
                            activeThumbColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInSlide(
                        index: 3,
                        child: MenuListItem(
                          title: 'Backup Now',
                          subtitle: 'Sync Plans & History (.xlsx)',
                          icon: Icons.backup_rounded,
                          color: Colors.blue,
                          onTap: _handleBackupNow,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInSlide(
                        index: 4,
                        child: MenuListItem(
                          title: 'Restore from Cloud',
                          subtitle: 'Download & restore data from GDrive',
                          icon: Icons.settings_backup_restore_rounded,
                          color: Colors.orange,
                          onTap: _handleRestore,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // DATA MANAGEMENT SECTION
                    FadeInSlide(
                      index: 5,
                      child: SectionHeader(title: 'LOCAL DATA'),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      index: 6,
                      child: MenuListItem(
                        title: 'Export to Excel',
                        subtitle: 'Local Plans & History (.xlsx)',
                        icon: Icons.table_chart_rounded,
                        color: AppColors.success,
                        onTap: () => _handleExport(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      index: 7,
                      child: MenuListItem(
                        title: 'Import from File',
                        subtitle: 'Restore your history from file',
                        icon: Icons.file_download_rounded,
                        color: AppColors.accent,
                        onTap: () => _handleImport(context),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // DANGER ZONE
                    FadeInSlide(
                      index: 8,
                      child: SectionHeader(title: 'DANGER ZONE'),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      index: 9,
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
