import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/stats_filter.dart';
import '../../workout_log/repositories/workout_repository.dart';
import '../../../shared/widgets/app_dialogs.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late List<WorkoutSession> _sessions;
  late TimePeriod _selectedPeriod;
  late ScrollController _scrollController;
  bool _showStickySelectorBar = false;
  bool _isLoading = true;
  String? _errorMessage;
  late int _userId;
  int _prCurrentPage = 0; // Pagination for personal records
  Set<String> _prSelectedExercises = {}; // Filter exercises to show
  late ScreenshotController _screenshotController;
  late ScreenshotController _sharePreviewController;

  // For period selection
  late DateTime _referenceDate;

  @override
  void initState() {
    super.initState();
    _sessions = [];
    _selectedPeriod = TimePeriod.week;
    _referenceDate = DateTime.now();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _screenshotController = ScreenshotController();
    _sharePreviewController = ScreenshotController();

    // Default local user ID
    _userId = 1;
    _loadWorkoutData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutData({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Get date range based on selected period with reference date
      final filter = StatsFilter(
        timePeriod: _selectedPeriod,
        referenceDate: _referenceDate,
      );
      final startDate = filter.getStartDate();
      final endDate = filter.getEndDate();

      // Debug log
      print('[STATS] Loading workouts for period: $_selectedPeriod');
      print('[STATS]   Reference date: $_referenceDate');
      print('[STATS]   Filter start: $startDate');
      print('[STATS]   Filter end: $endDate');

      // Load workouts from local repository
      final workoutRepository = WorkoutRepository();
      final allWorkouts = await workoutRepository.getWorkouts(
        userId: _userId.toString(),
      );

      print('[STATS] Total workouts from repository: ${allWorkouts.length}');
      for (var i = 0; i < allWorkouts.length; i++) {
        print('[STATS]   Workout $i: date=${allWorkouts[i].workoutDate}, exercises=${allWorkouts[i].exercises.length}');
      }

      // Filter workouts by date range
      final filteredWorkouts = allWorkouts.where((session) {
        final isAfter = session.workoutDate.isAfter(
          startDate.subtract(const Duration(days: 1)),
        );
        final isBefore = session.workoutDate.isBefore(
          endDate.add(const Duration(days: 1)),
        );
        print('[STATS]   Workout ${session.workoutDate}: isAfter=$isAfter, isBefore=$isBefore -> included=${isAfter && isBefore}');
        return isAfter && isBefore;
      }).toList();

      print('[STATS] Filtered workouts: ${filteredWorkouts.length}');

      setState(() {
        _sessions = filteredWorkouts;
        if (showLoading) {
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        if (showLoading) {
          _isLoading = false;
        }
      });
    }
  }

  void _onScroll() {
    // Show sticky selector when scrolled past the original selector
    setState(() {
      _showStickySelectorBar = _scrollController.offset > 100;
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
    final filter = StatsFilter(
      timePeriod: _selectedPeriod,
      referenceDate: _referenceDate,
    );
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
                      referenceDate: _referenceDate,
                      onPeriodChanged: (period) {
                        setState(() {
                          _selectedPeriod = period;
                          _referenceDate = DateTime.now();
                          _prCurrentPage = 0; // Reset pagination
                        });
                        // Reload data with new date range (no loading for local storage)
                        _loadWorkoutData(showLoading: false);
                      },
                      onDateChanged: (date) {
                        setState(() {
                          _referenceDate = date;
                        });
                        // Reload data with new date range (no loading for local storage)
                        _loadWorkoutData(showLoading: false);
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
                    const SizedBox(height: 8),
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
                      const SizedBox(height: 8),

                      // Volume Trend Chart
                      _VolumeChartCard(sessions: filteredSessions),
                      const SizedBox(height: 20),

                      // Workout Frequency Chart
                      _WorkoutFrequencyCard(
                        sessions: filteredSessions,
                        timePeriod: _selectedPeriod,
                        referenceDate: _referenceDate,
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
                    const SizedBox(height: 14),
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
          // Sticky Time Period Selector - Shows only when scrolled past original
          if (_showStickySelectorBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(16),
                  child: _TimePeriodSelector(
                    selectedPeriod: _selectedPeriod,
                    referenceDate: _referenceDate,
                    onPeriodChanged: (period) {
                      setState(() {
                        _selectedPeriod = period;
                        _referenceDate = DateTime.now();
                        _prCurrentPage = 0; // Reset pagination
                      });
                      // Reload data with new date range (no loading for local storage)
                      _loadWorkoutData(showLoading: false);
                    },
                    onDateChanged: (date) {
                      setState(() {
                        _referenceDate = date;
                      });
                      // Reload data with new date range (no loading for local storage)
                      _loadWorkoutData(showLoading: false);
                    },
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
              height:
                  1067, // 600 * 16/9 for perfect 9:16 aspect ratio with footer space
              child: Screenshot(
                controller: _sharePreviewController,
                child: _StatsSharePreview(
                  selectedPeriod: _selectedPeriod,
                  sessions: _getFilteredSessions(),
                  referenceDate: _referenceDate,
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
  final DateTime referenceDate;

  const _StatsSharePreview({
    required this.selectedPeriod,
    required this.sessions,
    required this.referenceDate,
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
    return num.toStringAsFixed(
      0,
    ).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',');
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20),

            // Trends - Same as app
            if (filteredSessions.isNotEmpty) ...[
              Text(
                'Trends',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              _VolumeChartCard(sessions: filteredSessions),
              const SizedBox(height: 20),
              _WorkoutFrequencyCard(
                sessions: filteredSessions,
                timePeriod: selectedPeriod,
                referenceDate: referenceDate,
              ),
            ] else ...[
              Text(
                'Trends',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
  final DateTime referenceDate;

  const _WorkoutFrequencyCard({
    required this.sessions,
    required this.timePeriod,
    required this.referenceDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = referenceDate;

    // Determine period range and labels based on timePeriod
    List<int> frequencyData = [];
    List<String> labels = [];
    String title = '';

    switch (timePeriod) {
      case TimePeriod.week:
        // Monday to Sunday (7 days)
        final dayOfWeek = now.weekday;
        final mondayOfWeek = now.subtract(Duration(days: dayOfWeek - 1));
        final sundayOfWeek = mondayOfWeek.add(const Duration(days: 6));
        
        title = 'Workout Frequency (${DateFormat('MMM d').format(mondayOfWeek)} - ${DateFormat('MMM d').format(sundayOfWeek)})';
        frequencyData = List.filled(7, 0);

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
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        
        title = 'Workout Frequency (${DateFormat('MMMM yyyy').format(now)})';

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
        title = 'Workout Frequency (${now.year})';
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
class _TimePeriodSelector extends StatefulWidget {
  final TimePeriod selectedPeriod;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final DateTime referenceDate;
  final ValueChanged<DateTime> onDateChanged;

  const _TimePeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.referenceDate,
    required this.onDateChanged,
  });

  @override
  State<_TimePeriodSelector> createState() => _TimePeriodSelectorState();
}

class _TimePeriodSelectorState extends State<_TimePeriodSelector> {
  String _getDisplayValue(DateTime ref) {
    switch (widget.selectedPeriod) {
      case TimePeriod.week:
        final weekStart = ref.subtract(Duration(days: ref.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
      case TimePeriod.month:
        return '${_monthName(ref.month)} ${ref.year}';
      case TimePeriod.year:
        return '${ref.year}';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    // Add leading zero for single digit days
    final dayStr = date.day.toString().padLeft(2, '0');
    return '$dayStr ${months[date.month - 1]}';
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _navigatePrevious(DateTime ref) {
    switch (widget.selectedPeriod) {
      case TimePeriod.week:
        widget.onDateChanged(ref.subtract(const Duration(days: 7)));
        break;
      case TimePeriod.month:
        widget.onDateChanged(DateTime(ref.year, ref.month - 1));
        break;
      case TimePeriod.year:
        widget.onDateChanged(DateTime(ref.year - 1));
        break;
    }
  }

  void _navigateNext(DateTime ref, DateTime now) {
    switch (widget.selectedPeriod) {
      case TimePeriod.week:
        widget.onDateChanged(ref.add(const Duration(days: 7)));
        break;
      case TimePeriod.month:
        widget.onDateChanged(DateTime(ref.year, ref.month + 1));
        break;
      case TimePeriod.year:
        widget.onDateChanged(DateTime(ref.year + 1));
        break;
    }
  }

  bool _canNavigatePrevious(DateTime ref, DateTime now) {
    switch (widget.selectedPeriod) {
      case TimePeriod.week:
        // Can always go back for weekly (like monthly)
        return true;
      case TimePeriod.month:
        return true; // Can always go back for month
      case TimePeriod.year:
        return true; // Can always go back for year
    }
  }

  bool _canNavigateNext(DateTime ref, DateTime now) {
    switch (widget.selectedPeriod) {
      case TimePeriod.week:
        // For weekly: next week must have started (weekStart <= today)
        final nextWeekStart = ref.add(const Duration(days: 7));
        final nowDate = DateTime(now.year, now.month, now.day);
        final nextWeekStartDate = DateTime(nextWeekStart.year, nextWeekStart.month, nextWeekStart.day);
        return !nextWeekStartDate.isAfter(nowDate);
      case TimePeriod.month:
        return (ref.month < now.month && ref.year == now.year) || ref.year < now.year;
      case TimePeriod.year:
        return ref.year < now.year;
    }
  }

  void _showWeekPicker(BuildContext context) async {
    final now = DateTime.now();
    await showDialog(
      context: context,
      builder: (_) => _WeekPickerDialog(
        referenceDate: widget.referenceDate,
        onWeekSelected: (date) {
          Navigator.pop(context);
          widget.onDateChanged(date);
        },
        nowYear: now.year,
      ),
    );
  }

  void _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    await showDialog(
      context: context,
      builder: (ctx) => _MonthPickerDialog(
        referenceDate: widget.referenceDate,
        onMonthSelected: (date) {
          Navigator.pop(ctx);
          widget.onDateChanged(date);
        },
        nowYear: now.year,
        nowMonth: now.month,
      ),
    );
  }

  void _showYearPicker(BuildContext context) {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Year',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          height: 250,
          width: double.maxFinite,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 10,
            itemBuilder: (context, index) {
              final year = now.year - 5 + index;
              final isSelected = year == widget.referenceDate.year;
              final canSelect = year <= now.year;

              return GestureDetector(
                onTap: canSelect
                    ? () {
                        widget.onDateChanged(DateTime(year));
                        Navigator.pop(context);
                      }
                    : null,
                child: Opacity(
                  opacity: canSelect ? 1.0 : 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.inputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.borderLight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        year.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ref = widget.referenceDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Period',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // Left: Value with arrow controls
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Back arrow
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        onPressed: _canNavigatePrevious(ref, now)
                            ? () => _navigatePrevious(ref)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        color: AppColors.accent,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        iconSize: 24,
                      ),
                    ),
                    // Value
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          switch (widget.selectedPeriod) {
                            case TimePeriod.week:
                              _showWeekPicker(context);
                              break;
                            case TimePeriod.month:
                              _showMonthPicker(context);
                              break;
                            case TimePeriod.year:
                              _showYearPicker(context);
                              break;
                          }
                        },
                        child: Text(
                          _getDisplayValue(ref),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Forward arrow
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        onPressed: _canNavigateNext(ref, now)
                            ? () => _navigateNext(ref, now)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        color: AppColors.accent,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        iconSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Dropdown period
              Expanded(
                child: DropdownButton<TimePeriod>(
                  value: widget.selectedPeriod,
                  onChanged: (TimePeriod? newValue) {
                    if (newValue != null) {
                      widget.onPeriodChanged(newValue);
                    }
                  },
                  dropdownColor: AppColors.cardBg,
                  elevation: 8,
                  isExpanded: true,
                  items: TimePeriod.values.map((TimePeriod period) {
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
                    size: 24,
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
                      return Center(
                        child: Text(
                          displayLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stateful Week Picker Dialog
class _WeekPickerDialog extends StatefulWidget {
  final DateTime referenceDate;
  final ValueChanged<DateTime> onWeekSelected;
  final int nowYear;

  const _WeekPickerDialog({
    required this.referenceDate,
    required this.onWeekSelected,
    required this.nowYear,
  });

  @override
  State<_WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<_WeekPickerDialog> {
  late int _selectedYear;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Handle cross-year weeks (e.g., Dec 29 - Jan 4)
    final ref = widget.referenceDate;
    _selectedYear = _determineYearForWeek(ref);
    
    // Scroll to selected week after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedWeek();
    });
  }

  /// Determine which year to display for the week containing the reference date
  /// If the reference date is early Jan and the week starts in Dec of previous year,
  /// show the previous year
  int _determineYearForWeek(DateTime ref) {
    final refYear = ref.year;
    
    // If in January, check if week starts in previous year
    if (ref.month == 1 && ref.day <= 10) {
      final refMonday = ref.subtract(Duration(days: ref.weekday - 1));
      // If the week's Monday is in December of previous year, use that year
      if (refMonday.year == refYear - 1) {
        return refYear - 1;
      }
    }
    
    return refYear;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changeYear(int newYear, int nowYear) {
    setState(() {
      _selectedYear = newYear;
    });
    
    // Determine if this year should scroll to selected week
    final ref = widget.referenceDate;
    final shouldScrollToSelected = _yearContainsSelectedWeek(newYear, ref);
    
    // Scroll based on whether the year contains the selected week
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldScrollToSelected) {
        // Year contains the selected week: scroll to selected week
        _scrollToSelectedWeek();
      } else {
        // Other year: scroll to top
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  /// Check if a year contains the week that has the reference date
  /// For example, if ref is 02 Jan 2026, the week starts on 29 Dec 2025
  /// So year 2025 contains the selected week, but 2026 does not
  bool _yearContainsSelectedWeek(int checkYear, DateTime ref) {
    // Find Monday of the week containing reference date
    DateTime refMonday = ref.subtract(Duration(days: ref.weekday - 1));
    // The year that "owns" this week is the year of the Monday
    return refMonday.year == checkYear;
  }

  void _scrollToSelectedWeek() {
    final ref = widget.referenceDate;
    
    // Find first Monday of the year
    DateTime firstDay = DateTime(_selectedYear);
    while (firstDay.weekday != DateTime.monday) {
      firstDay = firstDay.add(const Duration(days: 1));
    }

    // Find which week contains the reference date
    for (int weekNum = 1; ; weekNum++) {
      final weekDate = firstDay.add(Duration(days: (weekNum - 1) * 7));
      final weekEnd = weekDate.add(const Duration(days: 6));
      
      // Check if this week contains the reference date
      if (ref.isAfter(weekDate.subtract(const Duration(days: 1))) &&
          ref.isBefore(weekEnd.add(const Duration(days: 1)))) {
        // Scroll to this week
        // With 4 columns, each row has 4 items
        final row = (weekNum - 1) ~/ 4;
        final itemHeight = 80.0; // Approximate height of each item
        final offset = row * itemHeight;
        
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        break;
      }
      
      // Stop if we've gone past the end of the year
      if (weekDate.month == 12 && weekDate.day > 25) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = widget.referenceDate;

    // Find first Monday of the year
    DateTime firstDay = DateTime(_selectedYear);
    while (firstDay.weekday != DateTime.monday) {
      firstDay = firstDay.add(const Duration(days: 1));
    }

    // Find last Sunday of the year
    DateTime lastDay = DateTime(_selectedYear, 12, 31);
    while (lastDay.weekday != DateTime.sunday) {
      lastDay = lastDay.add(const Duration(days: 1));
    }

    final weeksInYear = ((lastDay.difference(firstDay).inDays + 1) ~/ 7);

    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Select Week',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    _changeYear(_selectedYear - 1, widget.nowYear);
                  },
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.accent,
                ),
                Text(
                  _selectedYear.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: _selectedYear < widget.nowYear
                      ? () {
                          _changeYear(_selectedYear + 1, widget.nowYear);
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Week list
          SizedBox(
            height: 300,
            width: double.maxFinite,
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: weeksInYear,
              itemBuilder: (ctx, index) {
                final weekNum = index + 1;
                final weekDate = firstDay.add(
                  Duration(days: (weekNum - 1) * 7),
                );
                // Check if this week contains the reference date
                final weekEnd = weekDate.add(const Duration(days: 6));
                // Compare dates ignoring time of day
                final refDate = DateTime(ref.year, ref.month, ref.day);
                final weekStartDate = DateTime(weekDate.year, weekDate.month, weekDate.day);
                final weekEndDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
                final isSelected = refDate.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
                    refDate.isBefore(weekEndDate.add(const Duration(days: 1)));

                // Check if week is in the past or present (can be selected)
                final now = DateTime.now();
                
                // Can select if week has started (weekStart <= today)
                final nowDate = DateTime(now.year, now.month, now.day);
                final canSelectSimple = !weekStartDate.isAfter(nowDate);

                return GestureDetector(
                  onTap: canSelectSimple ? () {
                    widget.onWeekSelected(weekDate);
                  } : null,
                  child: Opacity(
                    opacity: canSelectSimple ? 1.0 : 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.inputBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'W$weekNum',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Stateful Month Picker Dialog
class _MonthPickerDialog extends StatefulWidget {
  final DateTime referenceDate;
  final ValueChanged<DateTime> onMonthSelected;
  final int nowYear;
  final int nowMonth;

  const _MonthPickerDialog({
    required this.referenceDate,
    required this.onMonthSelected,
    required this.nowYear,
    required this.nowMonth,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.referenceDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final ref = widget.referenceDate;

    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Select Month',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedYear--;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.accent,
                ),
                Text(
                  _selectedYear.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: _selectedYear < widget.nowYear
                      ? () {
                          setState(() {
                            _selectedYear++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Month grid
          SizedBox(
            height: 250,
            width: double.maxFinite,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (ctx, index) {
                final month = index + 1;
                final isSelected =
                    month == ref.month && _selectedYear == ref.year;
                final canSelect =
                    (month <= widget.nowMonth &&
                        _selectedYear == widget.nowYear) ||
                    _selectedYear < widget.nowYear;

                return GestureDetector(
                  onTap: canSelect
                      ? () {
                          widget.onMonthSelected(
                            DateTime(_selectedYear, month),
                          );
                        }
                      : null,
                  child: Opacity(
                    opacity: canSelect ? 1.0 : 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.inputBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          months[index].substring(0, 3),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
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
