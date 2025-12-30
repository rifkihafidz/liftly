import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/stats_filter.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late List<WorkoutSession> _sessions;
  late TimePeriod _selectedPeriod;
  late ScrollController _scrollController;
  bool _showFloatingPeriodSelector = false;
  bool _isLoading = true;
  String? _errorMessage;
  late int _userId;
  int _prCurrentPage = 0; // Pagination for personal records
  Set<String> _prSelectedExercises = {}; // Filter exercises to show
  late ScreenshotController _screenshotController;
  late ScreenshotController _sharePreviewController;

  @override
  void initState() {
    super.initState();
    _sessions = [];
    _selectedPeriod = TimePeriod.week;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _screenshotController = ScreenshotController();
    _sharePreviewController = ScreenshotController();

    // Get userId from AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _userId = int.parse(authState.user.id);
      _loadWorkoutData();
    } else {
      setState(() {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get date range based on selected period
      final filter = StatsFilter(timePeriod: _selectedPeriod);
      final startDate = filter.getStartDate();
      final endDate = filter.getEndDate();

      // Call stats summary endpoint - single call gets ALL data
      final response = await ApiService.getStatsSummary(
        userId: _userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success && response.data != null) {
        final statsData = response.data!;

        // Convert workouts from the response to WorkoutSession objects
        final sessions = statsData.workouts
            .map(
              (workoutMap) =>
                  WorkoutSession.fromMap(workoutMap as Map<String, dynamic>),
            )
            .toList();

        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    setState(() {
      _showFloatingPeriodSelector = _scrollController.offset > 50;
    });
  }

  // Helper function to format numbers with thousand separators
  String _formatNumber(double num) {
    return num.toStringAsFixed(
      0,
    ).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',');
  }

  /// Show filter dialog for personal records
  void _showPRFilterDialog(
    BuildContext context,
    Map<String, double> allRecords,
  ) {
    final exercisesList = allRecords.keys.toList();
    final selectedExercises = Set<String>.from(
      _prSelectedExercises.isEmpty ? exercisesList : _prSelectedExercises,
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Exercises',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: exercisesList.length,
                        itemBuilder: (context, index) {
                          final exercise = exercisesList[index];
                          final weight = allRecords[exercise] ?? 0;
                          return CheckboxListTile(
                            title: Text(exercise),
                            subtitle: Text('${weight.toStringAsFixed(1)} kg'),
                            value: selectedExercises.contains(exercise),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedExercises.add(exercise);
                                } else {
                                  selectedExercises.remove(exercise);
                                }
                              });
                            },
                            dense: true,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() => selectedExercises.clear());
                            },
                            child: const Text('Clear All'),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: selectedExercises.isEmpty
                                    ? null
                                    : () {
                                        this.setState(() {
                                          _prSelectedExercises =
                                              selectedExercises;
                                          _prCurrentPage =
                                              0; // Reset pagination
                                        });
                                        Navigator.pop(context);
                                      },
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Share stats as Instagram story image (9:16 aspect ratio: 1080x1920)
  Future<void> _shareAsStoryImage() async {
    try {
      // Show loading
      if (!mounted) return;
      // Note: For image operations, snackbar is fine for simple status
      // but let's keep it simple for this case

      // Capture the share preview widget
      var image = await _sharePreviewController.capture(
        delay: const Duration(milliseconds: 300),
        pixelRatio: 2.0,
      );

      if (image == null) {
        if (!mounted) return;
        AppDialogs.showErrorDialog(
          context: context,
          title: 'Capture Failed',
          message: 'Gagal menangkap screenshot. Silakan coba lagi.',
        );
        return;
      }

      // Resize image to fit 9:16 (Instagram story format)
      image = await _resizeImageTo(image);

      // Share using SharePlus with file data
      try {
        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile.fromData(
            image,
            mimeType: 'image/png',
            name: 'liftly_stats.png',
          ),
        ], text: 'Check out my workout stats! 💪');
      } catch (shareError) {
        // Fallback to simple text share if file sharing fails
        final shareText =
            'Check out my workout stats! 💪\n\n'
            'Period: ${_selectedPeriod.label}\n'
            'Workouts: ${_getFilteredSessions().length}';

        // ignore: deprecated_member_use
        await Share.share(shareText);
      }
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Share Error',
        message: 'Gagal membagikan. Error: ${e.toString()}',
      );
    }
  }

  /// Resize captured image to maintain quality
  /// Keeps aspect ratio as-is (already 9:16 from preview)
  Future<Uint8List> _resizeImageTo(Uint8List imageData) async {
    // Return image as-is since it's already captured at correct aspect ratio
    return imageData;
  }

  List<WorkoutSession> _getFilteredSessions() {
    final filter = StatsFilter(timePeriod: _selectedPeriod);
    return _sessions
        .where((session) => filter.isInPeriod(session.workoutDate))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics'), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics'), elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadWorkoutData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredSessions = _getFilteredSessions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareAsStoryImage,
            icon: const Icon(Icons.share),
            tooltip: 'Share as story',
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Screenshot(
                controller: _screenshotController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== TIME PERIOD SELECTOR =====
                    _TimePeriodSelector(
                      selectedPeriod: _selectedPeriod,
                      onPeriodChanged: (period) {
                        setState(() {
                          _selectedPeriod = period;
                          _prCurrentPage = 0; // Reset pagination
                        });
                        // Reload data with new date range
                        _loadWorkoutData();
                      },
                    ),
                    const SizedBox(height: 28),

                    // ===== SUMMARY SECTION =====
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatBox(
                          label: 'Workouts',
                          value: filteredSessions.length.toString(),
                          icon: Icons.fitness_center,
                          color: AppColors.accent,
                        ),
                        _StatBox(
                          label: 'Volume',
                          value:
                              '${_formatNumber(_calculateTotalVolume(filteredSessions))} kg',
                          icon: Icons.scale,
                          color: AppColors.success,
                        ),
                        _StatBox(
                          label: 'Avg Time',
                          value: _calculateAverageDuration(filteredSessions),
                          icon: Icons.schedule,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ===== CHARTS SECTION =====
                    if (filteredSessions.isNotEmpty) ...[
                      Text(
                        'Trends',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Volume Trend Chart
                      _VolumeChartCard(sessions: filteredSessions),
                      const SizedBox(height: 20),

                      // Workout Frequency Chart
                      _WorkoutFrequencyCard(
                        sessions: filteredSessions,
                        timePeriod: _selectedPeriod,
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      Text(
                        'Trends',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EmptyStateCard(
                        icon: Icons.show_chart,
                        title: 'No Data Available',
                        message:
                            'No workouts recorded in this period.\nStart logging your workouts to see trends.',
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ===== PERSONAL RECORDS SECTION =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Personal Records',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_getPersonalRecords(
                          filteredSessions,
                        ).isNotEmpty) ...[
                          IconButton(
                            onPressed: () => _showPRFilterDialog(
                              context,
                              _getPersonalRecords(filteredSessions),
                            ),
                            icon: const Icon(Icons.tune),
                            iconSize: 20,
                            tooltip: 'Filter exercises',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (_getPersonalRecords(filteredSessions).isNotEmpty) ...[
                      Builder(
                        builder: (context) {
                          final allRecords = _getPersonalRecords(
                            filteredSessions,
                          ).entries.toList();

                          // Apply filter if selected
                          final filteredRecords = _prSelectedExercises.isEmpty
                              ? allRecords
                              : allRecords
                                    .where(
                                      (e) =>
                                          _prSelectedExercises.contains(e.key),
                                    )
                                    .toList();

                          if (filteredRecords.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No exercises selected',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            );
                          }

                          final itemsPerPage = 5;
                          final totalPages =
                              (filteredRecords.length / itemsPerPage).ceil();

                          // Reset page if out of bounds
                          if (_prCurrentPage >= totalPages) {
                            _prCurrentPage = 0;
                          }

                          final startIdx = _prCurrentPage * itemsPerPage;
                          final endIdx = (startIdx + itemsPerPage).clamp(
                            0,
                            filteredRecords.length,
                          );
                          final pageItems = filteredRecords.sublist(
                            startIdx,
                            endIdx,
                          );

                          return Column(
                            children: [
                              ...pageItems.map((entry) {
                                return _PRCard(
                                  exercise: entry.key,
                                  maxWeight: entry.value,
                                );
                              }),
                              if (totalPages > 1) ...[
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: _prCurrentPage > 0
                                          ? () {
                                              setState(() => _prCurrentPage--);
                                            }
                                          : null,
                                      icon: const Icon(Icons.arrow_back),
                                      iconSize: 20,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'Page ${_prCurrentPage + 1} of $totalPages',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _prCurrentPage < totalPages - 1
                                          ? () {
                                              setState(() => _prCurrentPage++);
                                            }
                                          : null,
                                      icon: const Icon(Icons.arrow_forward),
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      _EmptyStateCard(
                        icon: Icons.emoji_events,
                        title: 'No Records Yet',
                        message:
                            'Log your first workout to see personal records.\nYour best lifts will appear here.',
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Floating Period Selector
          if (_showFloatingPeriodSelector)
            Positioned(
              bottom: 24,
              right: 24,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.blue.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: PopupMenuButton<TimePeriod>(
                  itemBuilder: (BuildContext context) =>
                      TimePeriod.values.map((period) {
                        String label = '';
                        IconData icon = Icons.calendar_month;
                        switch (period) {
                          case TimePeriod.week:
                            label = 'Weekly';
                            icon = Icons.calendar_view_week;
                            break;
                          case TimePeriod.month:
                            label = 'Monthly';
                            icon = Icons.calendar_view_month;
                            break;
                          case TimePeriod.year:
                            label = 'Annually';
                            icon = Icons.calendar_today;
                            break;
                        }
                        return PopupMenuItem(
                          value: period,
                          child: Row(
                            children: [
                              Icon(icon, size: 18, color: AppColors.accent),
                              const SizedBox(width: 12),
                              Text(label),
                            ],
                          ),
                        );
                      }).toList(),
                  onSelected: (TimePeriod value) {
                    setState(() {
                      _selectedPeriod = value;
                      _prCurrentPage = 0; // Reset pagination
                    });
                    // Reload data with new date range
                    _loadWorkoutData();
                  },
                  offset: const Offset(-30, -130),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: AppColors.cardBg,
                  elevation: 12,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedPeriod.shortCode,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.expand_more,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Offscreen share preview widget for capture
          Positioned(
            left: -2000,
            top: 0,
            child: SizedBox(
              width: 600, // Wider to fit all content with footer
              height: 1067, // 600 * 16/9 for perfect 9:16 aspect ratio with footer space
              child: Screenshot(
                controller: _sharePreviewController,
                child: _StatsSharePreview(
                  selectedPeriod: _selectedPeriod,
                  sessions: _getFilteredSessions(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalVolume(List<WorkoutSession> sessions) {
    double total = 0;
    for (var session in sessions) {
      for (var exercise in session.exercises) {
        for (var set in exercise.sets) {
          for (var segment in set.segments) {
            total += segment.volume;
          }
        }
      }
    }
    return total;
  }

  String _calculateAverageDuration(List<WorkoutSession> sessions) {
    final durations = sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!)
        .toList();

    if (durations.isEmpty) return '-';

    final totalMinutes = durations.fold<int>(0, (sum, d) => sum + d.inMinutes);
    final avgMinutes = totalMinutes ~/ durations.length;

    return '${avgMinutes}m';
  }

  Map<String, double> _getPersonalRecords(List<WorkoutSession> sessions) {
    final records = <String, double>{};

    for (var session in sessions) {
      for (var exercise in session.exercises) {
        // Skip exercises that were marked as skipped
        if (exercise.skipped) continue;

        for (var set in exercise.sets) {
          for (var segment in set.segments) {
            final current = records[exercise.name] ?? 0;
            records[exercise.name] = segment.weight > current
                ? segment.weight
                : current;
          }
        }
      }
    }

    return Map.fromEntries(
      records.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }
}

/// Share Preview Widget - Optimized for 9:16 Instagram Story format
class _StatsSharePreview extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final List<WorkoutSession> sessions;

  const _StatsSharePreview({
    required this.selectedPeriod,
    required this.sessions,
  });

  double _calculateTotalVolume(List<WorkoutSession> sessions) {
    double total = 0;
    for (var session in sessions) {
      for (var exercise in session.exercises) {
        for (var set in exercise.sets) {
          for (var segment in set.segments) {
            total += segment.volume;
          }
        }
      }
    }
    return total;
  }

  String _calculateAverageDuration(List<WorkoutSession> sessions) {
    final durations = sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!)
        .toList();

    if (durations.isEmpty) return '-';

    final totalMinutes = durations.fold<int>(0, (sum, d) => sum + d.inMinutes);
    final avgMinutes = totalMinutes ~/ durations.length;

    return '${avgMinutes}m';
  }

  String _formatNumber(double num) {
    return num
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',');
  }

  @override
  Widget build(BuildContext context) {
    final filteredSessions = sessions;

    return Container(
      color: AppColors.cardBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Text(
                'My Workout Stats',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                selectedPeriod.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Overview - Same as app
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatBox(
                  label: 'Workouts',
                  value: filteredSessions.length.toString(),
                  icon: Icons.fitness_center,
                  color: AppColors.accent,
                ),
                _StatBox(
                  label: 'Volume',
                  value: '${_formatNumber(_calculateTotalVolume(filteredSessions))} kg',
                  icon: Icons.scale,
                  color: AppColors.success,
                ),
                _StatBox(
                  label: 'Avg Time',
                  value: _calculateAverageDuration(filteredSessions),
                  icon: Icons.schedule,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Trends - Same as app
            if (filteredSessions.isNotEmpty) ...[
              Text(
                'Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _VolumeChartCard(sessions: filteredSessions),
              const SizedBox(height: 20),
              _WorkoutFrequencyCard(
                sessions: filteredSessions,
                timePeriod: selectedPeriod,
              ),
            ] else ...[
              Text(
                'Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _EmptyStateCard(
                icon: Icons.show_chart,
                title: 'No Data Available',
                message:
                    'No workouts recorded in this period.\nStart logging your workouts to see trends.',
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: Text(
                '✨ Built with Liftly ✨',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact stat box for share preview

/// Volume Trend Chart Card
class _VolumeChartCard extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _VolumeChartCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // Sort sessions by date and calculate volume for each
    final sortedSessions = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));

    final volumeData = sortedSessions.map((session) {
      double volume = 0;
      for (var exercise in session.exercises) {
        for (var set in exercise.sets) {
          for (var segment in set.segments) {
            volume += segment.volume;
          }
        }
      }
      return volume;
    }).toList();

    final maxVolume = volumeData.isEmpty
        ? 100.0
        : volumeData.reduce((a, b) => a > b ? a : b);

    List<FlSpot> spots = [];
    for (int i = 0; i < volumeData.length; i++) {
      spots.add(FlSpot(i.toDouble(), volumeData[i]));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.15),
            AppColors.success.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVolume > 0
                      ? (maxVolume / 4).ceilToDouble()
                      : 100,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.success.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: volumeData.length <= 5
                          ? 1
                          : (volumeData.length / 5).ceilToDouble(),
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedSessions.length) {
                          return const SizedBox.shrink();
                        }
                        final date = sortedSessions[index].workoutDate;
                        final monthName = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ][date.month - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '$monthName ${date.day}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxVolume > 0
                          ? (maxVolume / 3).ceilToDouble()
                          : 100,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final formatted = value
                            .toInt()
                            .toString()
                            .replaceAllMapped(
                              RegExp(r'\B(?=(\d{3})+(?!\d))'),
                              (Match m) => ',',
                            );
                        return Text(
                          '$formatted kg',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                        );
                      },
                      reservedSize: 50,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.success.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: AppColors.success.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                barGroups: List.generate(
                  volumeData.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: volumeData[index],
                        color: AppColors.success,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                maxY: maxVolume * 1.1,
                alignment: BarChartAlignment.spaceAround,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${volumeData.fold<double>(0, (prev, vol) => prev + vol).toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',')} kg',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Avg: ${(volumeData.fold<double>(0, (prev, vol) => prev + vol) / (volumeData.isNotEmpty ? volumeData.length : 1)).toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',')} kg',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Workout Frequency Chart Card
class _WorkoutFrequencyCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final TimePeriod timePeriod;

  const _WorkoutFrequencyCard({
    required this.sessions,
    required this.timePeriod,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Determine period range and labels based on timePeriod
    List<int> frequencyData = [];
    List<String> labels = [];
    String title = '';

    switch (timePeriod) {
      case TimePeriod.week:
        // Monday to Sunday (7 days)
        title = 'Workout Frequency (This Week)';
        frequencyData = List.filled(7, 0);
        final dayOfWeek = now.weekday;
        final mondayOfWeek = now.subtract(Duration(days: dayOfWeek - 1));

        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        labels = dayNames;

        // Count sessions for each day
        for (int i = 0; i < 7; i++) {
          final dayDate = mondayOfWeek.add(Duration(days: i));
          final count = sessions
              .where(
                (s) =>
                    s.workoutDate.year == dayDate.year &&
                    s.workoutDate.month == dayDate.month &&
                    s.workoutDate.day == dayDate.day,
              )
              .length;
          frequencyData[i] = count;
        }
        break;

      case TimePeriod.month:
        // Group by weeks in current month
        title = 'Workout Frequency (This Month)';
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

        // Calculate weeks
        int daysToAdd =
            firstDayOfMonth.weekday - 1; // Days before Monday of first week

        // Count weeks
        int totalDays = lastDayOfMonth.day + daysToAdd;
        int weeksCount = (totalDays / 7).ceil();

        frequencyData = List.filled(weeksCount, 0);

        for (int i = 1; i <= lastDayOfMonth.day; i++) {
          final dayDate = DateTime(now.year, now.month, i);
          // Determine which week this day belongs to
          final weekIndex = ((dayDate.weekday - 1 + (i - 1)) / 7).floor();

          final count = sessions
              .where(
                (s) =>
                    s.workoutDate.year == dayDate.year &&
                    s.workoutDate.month == dayDate.month &&
                    s.workoutDate.day == dayDate.day,
              )
              .length;

          if (weekIndex < frequencyData.length) {
            frequencyData[weekIndex] += count;
          }
        }

        // Create week labels
        for (int i = 0; i < weeksCount; i++) {
          labels.add('W${i + 1}');
        }
        break;

      case TimePeriod.year:
        // All months in current year
        title = 'Workout Frequency (This Year - Annually)';
        frequencyData = List.filled(12, 0);
        final monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        labels = monthNames;

        for (int i = 1; i <= 12; i++) {
          final count = sessions
              .where(
                (s) =>
                    s.workoutDate.month == i && s.workoutDate.year == now.year,
              )
              .length;
          frequencyData[i - 1] = count;
        }
        break;
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < frequencyData.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: frequencyData[i].toDouble(),
              color: AppColors.accent,
              width: timePeriod == TimePeriod.year ? 10 : 12,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: sessions.length.toDouble() > 0
                    ? sessions.length.toDouble()
                    : 3,
                color: AppColors.accent.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval:
                          timePeriod == TimePeriod.month &&
                              frequencyData.length > 10
                          ? 5
                          : 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[index],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: timePeriod == TimePeriod.year
                                      ? 11
                                      : 10,
                                ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval:
                          1, // Show every integer value (0, 1, 2, 3, etc.)
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                maxY: (sessions.isNotEmpty ? sessions.length : 3).toDouble(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Time Period Selector Widget - Dropdown
class _TimePeriodSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final ValueChanged<TimePeriod> onPeriodChanged;

  const _TimePeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Time Period',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          DropdownButton<TimePeriod>(
            value: selectedPeriod,
            onChanged: (TimePeriod? newValue) {
              if (newValue != null) {
                onPeriodChanged(newValue);
              }
            },
            dropdownColor: AppColors.cardBg,
            elevation: 8,
            items: TimePeriod.values.map((TimePeriod period) {
              // Map shortcodes to full names
              String displayLabel = '';
              switch (period) {
                case TimePeriod.week:
                  displayLabel = 'Weekly';
                  break;
                case TimePeriod.month:
                  displayLabel = 'Monthly';
                  break;
                case TimePeriod.year:
                  displayLabel = 'Annually';
                  break;
              }
              return DropdownMenuItem<TimePeriod>(
                value: period,
                child: Text(
                  displayLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
            underline: SizedBox.shrink(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppColors.accent,
              size: 28,
            ),
            selectedItemBuilder: (BuildContext context) {
              return TimePeriod.values.map((TimePeriod period) {
                String displayLabel = '';
                switch (period) {
                  case TimePeriod.week:
                    displayLabel = 'Weekly';
                    break;
                  case TimePeriod.month:
                    displayLabel = 'Monthly';
                    break;
                  case TimePeriod.year:
                    displayLabel = 'Annually';
                    break;
                }
                return Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}

/// Simple Stat Box Widget
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PRCard extends StatelessWidget {
  final String exercise;
  final double maxWeight;

  const _PRCard({required this.exercise, required this.maxWeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Personal Record',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              '${maxWeight.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',')} kg',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty State Card Widget
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
