import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/data_management_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';
import '../../../shared/widgets/navigation/active_tab_scope.dart';
import '../../../shared/widgets/cards/menu_list_item.dart';
import '../../../shared/widgets/text/section_header.dart';
import '../../plans/bloc/plan_bloc.dart';
import '../../plans/bloc/plan_event.dart';
import '../../workout_log/bloc/workout_bloc.dart';
import '../../workout_log/bloc/workout_event.dart';
import '../../stats/bloc/stats_bloc.dart';
import '../../stats/bloc/stats_event.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  GoogleSignInAccount? _currentUser;
  bool _isAutoBackupEnabled = false;
  bool _isLoading = false;
  StreamSubscription<GoogleSignInAccount?>? _authSubscription;
  late ScrollController _scrollController;
  int? _lastActiveTab;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeTab = ActiveTabScope.maybeOf(context);
    if (activeTab != null &&
        _lastActiveTab != null &&
        activeTab != _lastActiveTab &&
        activeTab == 4 &&
        _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _lastActiveTab = activeTab;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadBackupState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = BackupService().onCurrentUserChanged.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  bool get _isCheckingStatus {
    return BackupService().isInitializing;
  }

  bool get _isLoggedInCached {
    return BackupService().cachedEmail != null;
  }

  Future<void> _loadBackupState() async {
    try {
      final backupService = BackupService();

      // If it's already initializing from main.dart, we should rebuild to show checking state
      if (backupService.isInitializing) {
        setState(() {});
      }

      await backupService.init();
      _currentUser = backupService.currentUser;

      final backupEnabled =
          await HiveService.getPreference('auto_backup_enabled');

      if (mounted) {
        setState(() {
          _isAutoBackupEnabled = backupEnabled == 'true';
        });
      }
    } catch (e) {
      AppLogger.error('SettingsPage', 'Failed to load backup state', e);
    }
  }

  Future<void> _handleGoogleConnect() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Show loading popup as requested
    AppDialogs.showLoadingDialog(context, 'Connecting to Google Drive...');

    Object? error;
    try {
      AppLogger.debug('SettingsPage', 'Starting Google Sign-In...');
      final user = await BackupService().signIn();
      if (mounted) {
        if (user == null) {
          AppLogger.debug('SettingsPage', 'Sign-In cancelled by user');
          return;
        }
        AppLogger.debug('SettingsPage', 'Sign-In successful: ${user.email}');
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      AppLogger.error('SettingsPage', 'Sign-In error caught', e);
      error = e;
    } finally {
      if (mounted) {
        AppLogger.debug('SettingsPage', 'Hiding loading dialog...');
        try {
          AppDialogs.hideLoadingDialog(context);
        } catch (e) {
          AppLogger.error('SettingsPage', 'Error hiding dialog', e);
        }

        setState(() => _isLoading = false);

        if (error != null) {
          AppLogger.debug('SettingsPage', 'Showing error dialog...');
          // Small delay to ensure loading dialog is fully gone
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              AppDialogs.showErrorDialog(
                context: context,
                title: 'Connection Failed',
                message:
                    'Could not sign in to Google Drive.\n\nNote: Check for a small login prompt in the top-right corner of your browser.\n\nError: $error',
              );
            }
          });
        }
      }
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
    if (_isLoading) return;
    final exportType = await _showDataSelectionDialog(context);
    if (exportType == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    final progressNotifier = ValueNotifier<double>(0.0);
    final statusNotifier = ValueNotifier<String>('Starting...');
    AppDialogs.showProgressDialog(
      context,
      title: 'Cloud Backup',
      progress: progressNotifier,
      status: statusNotifier,
    );

    try {
      await BackupService().backupDatabase(
        exportOnlyPlans: exportType == 'plans',
        onProgress: (p, msg) {
          progressNotifier.value = p;
          statusNotifier.value = msg;
        },
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppDialogs.showSuccessDialog(
          context: context,
          title: 'Cloud Backup Successful',
          message:
              'Your data has been safely backed up to Google Drive (Liftly Backup folder).',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppDialogs.showErrorDialog(
          context: context,
          title: 'Cloud Backup Failed',
          message: e.toString(),
        );
      }
    } finally {
      progressNotifier.dispose();
      statusNotifier.dispose();
      if (mounted) setState(() => _isLoading = false);
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
    if (_isLoading) return;

    final exportType = await _showDataSelectionDialog(context);
    if (exportType == null) return;

    setState(() => _isLoading = true);
    if (!context.mounted) return;

    final progressNotifier = ValueNotifier<double>(0.0);
    final statusNotifier = ValueNotifier<String>('Starting...');
    AppDialogs.showProgressDialog(
      context,
      title: 'Exporting to Excel',
      progress: progressNotifier,
      status: statusNotifier,
    );

    try {
      final message = await DataManagementService.exportData(
        exportOnlyPlans: exportType == 'plans',
        onProgress: (p, msg) {
          progressNotifier.value = p;
          statusNotifier.value = msg;
        },
      );
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppDialogs.showSuccessDialog(
          context: context,
          title: 'Excel Export Successful',
          message: message,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await AppDialogs.showErrorDialog(
          context: context,
          title: 'Excel Export Failed',
          message: e.toString(),
        );
      }
    } finally {
      progressNotifier.dispose();
      statusNotifier.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    AppDialogs.showLoadingDialog(context, 'Checking for backups...');
    try {
      final backups = await BackupService().listBackups();

      if (mounted) AppDialogs.hideLoadingDialog(context);
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
              'Restoring from cloud will PERMANENTLY DELETE all current existing records and replace them with the backup data. This action cannot be undone. Are you sure?',
          confirmText: 'Clear & Restore',
          isDangerous: true,
        );

        if (confirmed == true) {
          if (!mounted) return;

          final progressNotifier = ValueNotifier<double>(0.0);
          final statusNotifier =
              ValueNotifier<String>('Starting Cloud restore...');

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PopScope(
              canPop: false,
              child: AlertDialog(
                backgroundColor: AppColors.cardBg,
                title: const Text(AppConstants.titleRestoreCloud,
                    style: TextStyle(color: AppColors.textPrimary)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: statusNotifier,
                      builder: (context, status, _) => Text(
                        status,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<double>(
                      valueListenable: progressNotifier,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        backgroundColor: AppColors.darkBg,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 300));

          await BackupService().restoreDatabase(
            selectedFileId,
            onProgress: (p, msg) {
              progressNotifier.value = p;
              statusNotifier.value = msg;
            },
          );

          if (!mounted) return;
          Navigator.pop(context); // Close progress dialog

          // Refresh Blocs so UI updates immediately
          context.read<PlanBloc>().add(const PlansFetchRequested(userId: AppConstants.defaultUserId));
          context.read<WorkoutBloc>().add(const WorkoutsFetched(userId: AppConstants.defaultUserId));
          context.read<StatsBloc>().add(const StatsFetched(userId: AppConstants.defaultUserId));

          AppDialogs.showSuccessDialog(
            context: context,
            title: 'Cloud Restore Successful',
            message:
                'Application data has been successfully restored from Google Drive.',
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
          title: 'Cloud Restore Failed',
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
        title: AppConstants.titleImportData,
        message:
            'Importing data will PERMANENTLY DELETE all current existing records and replace them with the backup data. This action cannot be undone. Are you sure?',
        confirmText: 'Clear & Import',
        isDangerous: true,
      );

      if (result != true) return;
      if (!context.mounted) return;

      // 1. Pick file first (UI responsive)
      final file = await DataManagementService.pickImportFile();
      if (file == null) return; // Cancelled

      if (!context.mounted) return;

      // 2. Show Progress Dialog
      // We use a StatefulBuilder or StateSetter to update the dialog content
      final progressNotifier = ValueNotifier<double>(0.0);
      final statusNotifier = ValueNotifier<String>('Starting...');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: const Text('Importing Data',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (context, status, _) => Text(
                    status,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.darkBg,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 3. Process with callback
      // Add a small delay for dialog to build
      await Future.delayed(const Duration(milliseconds: 300));

      final importResult = await DataManagementService.importFile(
        file,
        onProgress: (progress, message) {
          progressNotifier.value = progress;
          statusNotifier.value = message;
        },
      );

      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog

        // Refresh Blocs so UI updates immediately
        context.read<PlanBloc>().add(const PlansFetchRequested(userId: AppConstants.defaultUserId));
        context.read<WorkoutBloc>().add(const WorkoutsFetched(userId: AppConstants.defaultUserId));
        context.read<StatsBloc>().add(const StatsFetched(userId: AppConstants.defaultUserId));

        await AppDialogs.showSuccessDialog(
          context: context,
          title: 'Excel Import Successful',
          message: importResult,
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Close progress dialog if open
        Navigator.pop(context);

        await AppDialogs.showErrorDialog(
          context: context,
          title: 'Excel Import Failed',
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

    if (_isLoading) return;
    setState(() => _isLoading = true);
    if (!context.mounted) return;
    AppDialogs.showLoadingDialog(context, 'Clearing all data...');
    try {
      if (!context.mounted) return;
      await DataManagementService.clearAllData();
      if (context.mounted) {
        AppDialogs.hideLoadingDialog(context);
        if (context.mounted) {
          context.read<PlanBloc>().add(const PlansFetchRequested(userId: AppConstants.defaultUserId));
          context.read<WorkoutBloc>().add(const WorkoutsFetched(userId: AppConstants.defaultUserId));
          context.read<StatsBloc>().add(const StatsFetched(userId: AppConstants.defaultUserId));

          AppDialogs.showSuccessDialog(
            context: context,
            title: 'Success',
            message: 'All data cleared successfully',
          );
        }
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                leadingWidth: 56,
                leading: const SizedBox.shrink(),
                title: const Text('Settings'),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeInSlide(
                      index: 0,
                      child:
                          SectionHeader(title: AppConstants.headerCloudBackup),
                    ),
                    const SizedBox(height: 16),
                    if (_isCheckingStatus)
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
                    else if (_currentUser == null && !_isLoggedInCached)
                      FadeInSlide(
                        index: 1,
                        child: MenuListItem(
                          title: 'Connect Google Drive',
                          subtitle: 'Enable sync across your devices',
                          icon: Icons.cloud_outlined,
                          color: AppColors.accent,
                          onTap: _handleGoogleConnect,
                        ),
                      )
                    else ...[
                      FadeInSlide(
                        index: 1,
                        child: MenuListItem(
                          title: 'Google Account',
                          subtitle: _currentUser?.email ?? BackupService().cachedEmail ?? 'Connected',
                          icon: Icons.account_circle_outlined,
                          color: AppColors.accent,
                          onTap: () {},
                          trailing: TextButton(
                            onPressed: _handleGoogleDisconnect,
                            child: const Text('Logout'),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.itemSpacing),
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
                      const SizedBox(height: AppConstants.itemSpacing),
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
                      const SizedBox(height: AppConstants.itemSpacing),
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
                    const SizedBox(height: AppConstants.sectionSpacing),

                    // DATA MANAGEMENT SECTION
                    FadeInSlide(
                      index: 5,
                      child: SectionHeader(title: AppConstants.headerLocalData),
                    ),
                    const SizedBox(height: AppConstants.subSectionSpacing),
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
                    const SizedBox(height: AppConstants.itemSpacing),
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
                    const SizedBox(height: AppConstants.sectionSpacing),

                    // DANGER ZONE
                    FadeInSlide(
                      index: 8,
                      child:
                          SectionHeader(title: AppConstants.headerDangerZone),
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
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showDataSelectionDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          AppConstants.titleExportOptions,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Everything (Workouts & Plans)',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              leading: const Icon(Icons.all_inclusive, color: AppColors.accent),
              onTap: () => Navigator.pop(context, 'everything'),
            ),
            ListTile(
              title: const Text(
                'Plans Only',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              leading: const Icon(Icons.list_alt, color: AppColors.success),
              onTap: () => Navigator.pop(context, 'plans'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
