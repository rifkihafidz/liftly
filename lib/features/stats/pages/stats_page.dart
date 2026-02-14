import 'package:flutter/material.dart';
import '../../session/widgets/session_exercise_history_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/personal_record.dart';
import '../../../core/models/stats_filter.dart';

import '../../../shared/widgets/app_dialogs.dart';
import '../bloc/stats_bloc.dart';
import '../bloc/stats_event.dart';
import '../bloc/stats_state.dart';
import 'stats_shimmer.dart';
import '../../../shared/widgets/animations/fade_in_slide.dart';
import '../../../shared/widgets/cards/stat_overview_card.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late ScrollController _scrollController;
  int _prCurrentPage = 0; // Pagination for personal records
  late ScreenshotController _sharePreviewController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _sharePreviewController = ScreenshotController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper function to format numbers with thousand separators
  String _formatNumber(double num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
    }
    return NumberFormat('#,##0.##', 'pt_BR').format(num);
  }

  /// Show filter dialog for personal records
  void _showPRFilterDialog(
    BuildContext context,
    Map<String, PersonalRecord> allRecords, // Changed from double
    Set<String> currentSelections,
  ) {
    final statsBloc = context.read<StatsBloc>();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: statsBloc,
          child: _ExerciseFilterDialog(
            allRecords: allRecords,
            currentSelections: currentSelections,
            onApply: (selected) {
              statsBloc.add(StatsPRFiltered(selectedExercises: selected));
              setState(() {
                _prCurrentPage = 0; // Reset pagination
              });
            },
          ),
        );
      },
    );
  }

  /// Share stats as Instagram story image (9:16 aspect ratio: 1080x1920)
  Future<void> _shareAsStoryImage(
    BuildContext context,
    StatsLoaded state,
  ) async {
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
        if (!context.mounted) return;
        AppDialogs.showErrorDialog(
          context: context,
          title: 'Capture Failed',
          message: 'Failed to capture screenshot. Please try again.',
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
        final shareText = 'Check out my workout stats! 💪\n\n'
            'Period: ${state.timePeriod.label}\n'
            'Workouts: ${state.filteredSessions.length}';

        // ignore: deprecated_member_use
        await Share.share(shareText);
      }
    } catch (e) {
      if (!context.mounted) return;
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Share Error',
        message: 'Failed to share. Error: ${e.toString()}',
      );
    }
  }

  /// Share filtered Personal Records
  Future<void> _sharePRs(
    BuildContext context,
    Map<String, PersonalRecord> allRecords,
    Set<String> filter,
  ) async {
    try {
      // 1. Filter records
      final filteredRecords = (filter.isEmpty)
          ? allRecords
          : Map.fromEntries(
              allRecords.entries.where((e) => filter.contains(e.key)),
            );

      if (filteredRecords.isEmpty) {
        if (!mounted) return;
        AppDialogs.showErrorDialog(
          context: context,
          title: 'Nothing to Share',
          message: 'No personal records found with the current filter.',
        );
        return;
      }

      // 2. Capture using ScreenshotController (from an invisible widget)
      final image = await _sharePreviewController.captureFromWidget(
        _PRSharePreview(records: filteredRecords),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
        context: context, // Provide context for Theme/Media access
      );

      // 3. Share
      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile.fromData(image, mimeType: 'image/png', name: 'liftly_prs.png'),
      ], text: 'My Personal Records on Liftly! 🏆');
    } catch (e) {
      if (!context.mounted) return;
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Share Failed',
        message: 'Failed to share records. Error: $e',
      );
    }
  }

  /// Resize captured image to maintain quality
  /// Keeps aspect ratio as-is (already 9:16 from preview)
  Future<Uint8List> _resizeImageTo(Uint8List imageData) async {
    // Return image as-is since it's already captured at correct aspect ratio
    return imageData;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatsBloc()..add(const StatsFetched(userId: '1')),
      child: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (state is StatsLoading) {
            return const StatsPageShimmer();
          }

          if (state is StatsError) {
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
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        context.read<StatsBloc>().add(
                              const StatsFetched(userId: '1'),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is StatsLoaded) {
            final filteredSessions = state.filteredSessions;

            return Scaffold(
              body: Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        centerTitle: false,
                        backgroundColor: AppColors.darkBg,
                        surfaceTintColor: AppColors.darkBg,
                        elevation: 0,
                        title: Text(
                          'Statistics',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        actions: [
                          IconButton(
                            onPressed: () => _shareAsStoryImage(context, state),
                            icon: const Icon(Icons.share),
                            tooltip: 'Share as story',
                          ),
                        ],
                      ),
                      // Sticky Header for Time Period
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickySelectorDelegate(
                          child: Container(
                            color: AppColors.darkBg,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: _TimePeriodSelector(
                              selectedPeriod: state.timePeriod,
                              referenceDate: state.referenceDate,
                              onPeriodChanged: (period) {
                                context.read<StatsBloc>().add(
                                      StatsPeriodChanged(timePeriod: period),
                                    );
                              },
                              onDateChanged: (date) {
                                context.read<StatsBloc>().add(
                                      StatsDateChanged(date: date),
                                    );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Main Content
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildOverview(context, filteredSessions),
                            _buildDynamicContent(context, state),
                            const SizedBox(
                              height: 100,
                            ), // Padding to avoid footer overlap
                          ]),
                        ),
                      ),
                    ],
                  ),

                  // Offscreen share preview widget for capture
                  Positioned(
                    left: -2000,
                    top: 0,
                    child: SizedBox(
                      width: 720,
                      height: 1280,
                      child: Screenshot(
                        controller: _sharePreviewController,
                        child: _StatsSharePreview(
                          selectedPeriod: state.timePeriod,
                          sessions: filteredSessions,
                          referenceDate: state.referenceDate,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context,
    List<WorkoutSession> filteredSessions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 44),

        // ===== SUMMARY SECTION =====
        Text(
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 500 ? 5 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                FadeInSlide(
                  index: 0,
                  child: StatOverviewCard(
                    label: 'Workouts',
                    value: filteredSessions.length.toString(),
                    icon: Icons.fitness_center,
                    color: AppColors.accent,
                  ),
                ),
                FadeInSlide(
                  index: 1,
                  child: StatOverviewCard(
                    label: 'Total Volume',
                    value: _formatNumber(
                      _calculateTotalVolume(filteredSessions),
                    ),
                    unit: 'kg',
                    icon: Icons.scale,
                    color: AppColors.success,
                  ),
                ),
                FadeInSlide(
                  index: 2,
                  child: StatOverviewCard(
                    label: 'Total Time',
                    value: _calculateTotalDuration(filteredSessions),
                    icon: Icons.access_time_filled,
                    color: Colors.blue,
                  ),
                ),
                FadeInSlide(
                  index: 3,
                  child: StatOverviewCard(
                    label: 'Avg Time',
                    value: _calculateAverageDuration(filteredSessions),
                    icon: Icons.timer_outlined,
                    color: AppColors.warning,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDynamicContent(BuildContext context, StatsLoaded state) {
    final filteredSessions = state.filteredSessions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 44),

        // ===== TRENDS SECTION =====
        Text(
          'Trends',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        AnimatedCrossFade(
          firstChild: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren.map(
                      (child) =>
                          Positioned(top: 0, left: 0, right: 0, child: child),
                    ),
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: Column(
                key: ValueKey(
                  'trends-data-${state.timePeriod}-${state.referenceDate}',
                ),
                children: [
                  _VolumeChartCard(
                    sessions: filteredSessions,
                    timePeriod: state.timePeriod,
                    referenceDate: state.referenceDate,
                  ),
                  const SizedBox(height: 20),
                  _WorkoutFrequencyCard(
                    sessions: filteredSessions,
                    timePeriod: state.timePeriod,
                    referenceDate: state.referenceDate,
                  ),
                ],
              ),
            ),
          ),
          secondChild: Column(
            key: const ValueKey('trends-empty'),
            children: [
              _EmptyStateCard(
                icon: Icons.show_chart,
                title: 'No Data Available',
                message:
                    'No workouts recorded in this period.\nStart logging your workouts to see trends.',
              ),
            ],
          ),
          crossFadeState: filteredSessions.isNotEmpty
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),

        const SizedBox(height: 44),

        // ===== PERSONAL RECORDS SECTION =====
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personal Records',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (state.personalRecords.isNotEmpty) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _sharePRs(
                      context,
                      state.personalRecords,
                      state.prFilter ?? {},
                    ),
                    icon: const Icon(Icons.share_outlined),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  // Sort Button
                  PopupMenuButton<PrSortOrder>(
                    initialValue: state.sortOrder,
                    onSelected: (order) {
                      context
                          .read<StatsBloc>()
                          .add(StatsPRSortChanged(sortOrder: order));
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: PrSortOrder.az,
                        child: Row(
                          children: [
                            Icon(Icons.sort_by_alpha, size: 18),
                            SizedBox(width: 8),
                            Text('A-Z'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: PrSortOrder.za,
                        child: Row(
                          children: [
                            Icon(Icons.sort_by_alpha, size: 18),
                            SizedBox(width: 8),
                            Text('Z-A'),
                          ],
                        ),
                      ),
                    ],
                    padding: EdgeInsets.zero,
                    child: const Icon(Icons.sort, size: 20),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => _showPRFilterDialog(
                      context,
                      state.personalRecords,
                      state.prFilter ?? {},
                    ),
                    icon: const Icon(Icons.tune),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          firstChild: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(
                'pr-data-${state.timePeriod}-${state.referenceDate}',
              ),
              child: _buildPersonalRecordsGrid(
                context,
                state.personalRecords,
                state.prFilter,
                state.allSessions,
                state.sortOrder,
              ),
            ),
          ),
          secondChild: KeyedSubtree(
            key: ValueKey(
              filteredSessions.isNotEmpty ? 'pr-norecords' : 'pr-empty',
            ), // Stable key for empty state?
            child: Column(
              children: [
                _EmptyStateCard(
                  icon: Icons.emoji_events,
                  title: 'No Records Yet',
                  message: filteredSessions.isNotEmpty
                      ? 'Keep pushing! Your personal records will appear here once you log them.'
                      : 'Log your first workout to see personal records.\nYour best lifts will appear here.',
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Logic:
          // If Sessions NOT Empty AND PRs NOT Empty -> Show First (Grid)
          // Else -> Show Second (Empty Card)
          crossFadeState: (state.filteredSessions.isNotEmpty &&
                  state.personalRecords.isNotEmpty)
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildPersonalRecordsGrid(
    BuildContext context,
    Map<String, PersonalRecord> records,
    Set<String>? filter,
    List<WorkoutSession> allSessions,
    PrSortOrder sortOrder,
  ) {
    // Apply filter
    final prsList = (filter == null || filter.isEmpty)
        ? records.entries.toList()
        : records.entries.where((e) => filter.contains(e.key)).toList();

    // Sort
    prsList.sort((a, b) {
      if (sortOrder == PrSortOrder.az) {
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      } else {
        return b.key.toLowerCase().compareTo(a.key.toLowerCase());
      }
    });
    final itemsPerPage = 4;
    final totalPages = (prsList.length / itemsPerPage).ceil();

    // Ensure current page is valid
    if (_prCurrentPage >= totalPages) {
      _prCurrentPage = 0;
    }

    final startIndex = _prCurrentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage < prsList.length)
        ? startIndex + itemsPerPage
        : prsList.length;

    final currentPRs = prsList.sublist(startIndex, endIndex);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.9, // Even more vertical space
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              padding: EdgeInsets.zero,
              itemCount: currentPRs.length,
              itemBuilder: (context, index) {
                final entry = currentPRs[index];
                return FadeInSlide(
                  index: index,
                  child: InkWell(
                    onTap: () {
                      // Find last session for this exercise using name for better compatibility
                      WorkoutSession? lastSession;
                      try {
                        final exerciseName = entry.value.exerciseName;
                        lastSession = allSessions.firstWhere((s) => s.exercises
                            .any((e) =>
                                e.name.toLowerCase() ==
                                exerciseName.toLowerCase()));
                      } catch (_) {
                        // ignore
                      }

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.cardBg,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => SessionExerciseHistorySheet(
                          exerciseName: entry.value.exerciseName,
                          history: lastSession,
                          pr: entry.value,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          // Decorative watermark
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Icon(
                              Icons.emoji_events_rounded,
                              size: 64,
                              color: AppColors.accent.withValues(alpha: 0.05),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.start, // Avoid stretching
                              children: [
                                Text(
                                  entry.value.exerciseName.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // Best 1 Set (Max Weight)
                                _buildPRValueRow(
                                  context,
                                  'Heaviest',
                                  entry.value.maxWeight,
                                  'kg',
                                  reps: entry.value.maxWeightReps,
                                ),
                                const SizedBox(height: 4),
                                // Best Volume Set (Max Vol)
                                _buildPRValueRow(
                                  context,
                                  'Best Vol',
                                  entry.value.maxVolume,
                                  'kg',
                                  details: entry.value.maxVolumeBreakdown,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 12),
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
              Text(
                '${_prCurrentPage + 1} / $totalPages',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
  }

  Widget _buildPRValueRow(
    BuildContext context,
    String label,
    double value,
    String unit, {
    int? reps,
    String? details,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _formatNumber(value),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (reps != null) ...[
              const SizedBox(width: 6),
              Text(
                'x $reps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
              ),
            ],
          ],
        ),
        if (details != null && details.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '($details)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 10,
                  height: 1.3,
                ),
          ),
        ],
      ],
    );
  }

  double _calculateTotalVolume(List<WorkoutSession> sessions) {
    double total = 0;
    for (var session in sessions) {
      total += session.totalVolume;
    }
    return total;
  }

  String _calculateTotalDuration(List<WorkoutSession> sessions) {
    final durations = sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!)
        .toList();

    if (durations.isEmpty) return '-';

    final totalDuration = durations.fold<Duration>(
      Duration.zero,
      (sum, d) => sum + d,
    );

    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _calculateAverageDuration(List<WorkoutSession> sessions) {
    final durations = sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!)
        .toList();

    if (durations.isEmpty) return '-';

    final totalMinutes = durations.fold<int>(0, (sum, d) => sum + d.inMinutes);
    final avgMinutes = totalMinutes ~/ durations.length;

    final hours = avgMinutes ~/ 60;
    final minutes = avgMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
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
      total += session.totalVolume;
    }
    return total;
  }

  String _calculateTotalDuration(List<WorkoutSession> sessions) {
    final durations = sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!)
        .toList();

    if (durations.isEmpty) return '-';

    final totalDuration = durations.fold<Duration>(
      Duration.zero,
      (sum, d) => sum + d,
    );

    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _calculateAverageDuration(List<WorkoutSession> sessions) {
    final durations = sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!)
        .toList();

    if (durations.isEmpty) return '-';

    final totalMinutes = durations.fold<int>(0, (sum, d) => sum + d.inMinutes);
    final avgMinutes = totalMinutes ~/ durations.length;

    final hours = avgMinutes ~/ 60;
    final minutes = avgMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatNumber(double num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
    }
    return NumberFormat('#,##0.##', 'pt_BR').format(num);
  }

  @override
  Widget build(BuildContext context) {
    final filteredSessions = sessions;

    return Container(
      width: 720,
      height: 1280,
      decoration: BoxDecoration(color: const Color(0xFF0B0F14)),
      child: Center(
        child: Container(
          width: 640,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF141A21),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER / BRANDING =====
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LIFTLY',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                fontSize: 18,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _getPeriodRange(
                          selectedPeriod,
                          referenceDate,
                        ).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontSize: 9,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ===== OVERVIEW SECTION =====
              _buildSectionTitle(context, 'OVERVIEW'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMiniStat(
                    context,
                    'WORKOUTS',
                    filteredSessions.length.toString(),
                    Icons.bolt,
                    AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  _buildMiniStat(
                    context,
                    'VOLUME',
                    '${_formatNumber(_calculateTotalVolume(filteredSessions))} kg',
                    Icons.fitness_center,
                    AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  _buildMiniStat(
                    context,
                    'TOTAL TIME',
                    _calculateTotalDuration(filteredSessions),
                    Icons.access_time_filled,
                    Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  _buildMiniStat(
                    context,
                    'AVG TIME',
                    _calculateAverageDuration(filteredSessions),
                    Icons.timer,
                    AppColors.warning,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ===== TRENDS SECTION =====
              _buildSectionTitle(context, 'ACTIVITY TRENDS'),
              const SizedBox(height: 8),
              if (filteredSessions.isNotEmpty) ...[
                _VolumeChartCard(
                  sessions: filteredSessions,
                  timePeriod: selectedPeriod,
                  referenceDate: referenceDate,
                  isCompact: true,
                ),
                const SizedBox(height: 10),
                _WorkoutFrequencyCard(
                  sessions: filteredSessions,
                  timePeriod: selectedPeriod,
                  referenceDate: referenceDate,
                  isCompact: true,
                ),
              ] else ...[
                _EmptyStateCard(
                  icon: Icons.show_chart,
                  title: 'No Data',
                  message: 'Log workouts to see your growth.',
                ),
              ],

              const SizedBox(height: 24),
              Divider(color: Colors.white.withValues(alpha: 0.05)),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Track your progress with Liftly',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'liftly.app',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accent.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 9,
          ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.15), Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodRange(TimePeriod period, DateTime ref) {
    switch (period) {
      case TimePeriod.week:
        final weekStart = ref.subtract(Duration(days: ref.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
      case TimePeriod.month:
        return '${_monthName(ref.month)} ${ref.year}';
      case TimePeriod.year:
        return '${ref.year}';
      case TimePeriod.allTime:
        return 'All Time';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
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
    final dayStr = date.day.toString().padLeft(2, '0');
    return '$dayStr ${months[date.month - 1]}';
  }

  String _monthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}

/// Compact stat box for share preview

/// Volume Trend Chart Card
class _VolumeChartCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final TimePeriod timePeriod;
  final DateTime referenceDate;
  final bool isCompact;

  const _VolumeChartCard({
    required this.sessions,
    required this.timePeriod,
    required this.referenceDate,
    this.isCompact = false,
  });

  String _formatCompactNumber(double num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(0)}k';
    }
    return NumberFormat('#,##0.##', 'pt_BR').format(num);
  }

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

    // 1. Prepare Data based on TimePeriod
    List<double> volumeData = [];
    List<String> labels = [];
    double totalVolume = 0;
    final now = referenceDate;

    String title = 'Volume Trend';
    switch (timePeriod) {
      case TimePeriod.week:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        title =
            'Volume Trend (${DateFormat('dd MMM').format(monday)} - ${DateFormat('dd MMM').format(sunday)})';
        break;
      case TimePeriod.month:
        title = 'Volume Trend (${DateFormat('MMMM yyyy').format(now)})';
        break;
      case TimePeriod.year:
        title = 'Volume Trend (${now.year})';
        break;
      case TimePeriod.allTime:
        title = 'Volume Trend (All Time)';
        break;
    }

    switch (timePeriod) {
      case TimePeriod.week:
        // Weekly: 7 days (Mon-Sun)
        final dayOfWeek = now.weekday;
        final mondayOfWeek = now.subtract(Duration(days: dayOfWeek - 1));

        volumeData = List.filled(7, 0.0);
        labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        for (var session in sessions) {
          // Calculate day index (0-6) based on difference from Monday
          final diff = session.effectiveDate.difference(mondayOfWeek).inDays;
          if (diff >= 0 && diff < 7) {
            volumeData[diff] += session.totalVolume;
          }
        }
        break;

      case TimePeriod.month:
        // Monthly: Days in month
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        volumeData = List.filled(daysInMonth, 0.0);

        // Labels: 1, 5, 10...
        labels = List.generate(daysInMonth, (index) => (index + 1).toString());

        for (var session in sessions) {
          if (session.effectiveDate.month == now.month &&
              session.effectiveDate.year == now.year) {
            final dayIndex = session.effectiveDate.day - 1;
            if (dayIndex >= 0 && dayIndex < daysInMonth) {
              volumeData[dayIndex] += session.totalVolume;
            }
          }
        }
        break;

      case TimePeriod.allTime:
        // All Time: Group by Year (Show range from 2024 to current year + 1 for context)
        final currentYear = now.year;
        final yearsFromData = sessions.map((s) => s.effectiveDate.year).toList()
          ..sort();
        final firstDataYear =
            yearsFromData.isEmpty ? currentYear : yearsFromData.first;
        final lastDataYear =
            yearsFromData.isEmpty ? currentYear : yearsFromData.last;

        // Broaden range: start at 2024 (or earlier if data exists), end at currentYear + 1
        final firstYear = firstDataYear < 2024 ? firstDataYear : 2024;
        final lastYear =
            lastDataYear > currentYear ? lastDataYear : currentYear + 1;

        final range = lastYear - firstYear + 1;

        volumeData = List.filled(range, 0.0);
        labels = List.generate(range, (i) => (firstYear + i).toString());

        for (var session in sessions) {
          final index = session.effectiveDate.year - firstYear;
          if (index >= 0 && index < range) {
            volumeData[index] += session.totalVolume;
          }
        }
        break;
      case TimePeriod.year:
        // Yearly: 12 months (Jan-Dec)
        volumeData = List.filled(12, 0.0);
        labels = [
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

        for (var session in sessions) {
          if (session.effectiveDate.year == now.year) {
            final monthIndex = session.effectiveDate.month - 1;
            if (monthIndex >= 0 && monthIndex < 12) {
              volumeData[monthIndex] += session.totalVolume;
            }
          }
        }
        break;
    }

    totalVolume = volumeData.fold(0, (sum, v) => sum + v);

    // Calculate max value for scaling
    final rawMax =
        volumeData.isEmpty ? 100.0 : volumeData.reduce((a, b) => a > b ? a : b);

    // Calculate a nice interval and max Y to prevent clashing labels and provide breathing room
    double chartInterval = 100;
    if (rawMax <= 0) {
      chartInterval = 100;
    } else {
      double targetInterval = rawMax / 3;
      if (targetInterval <= 10) {
        chartInterval = 10;
      } else if (targetInterval <= 25) {
        chartInterval = 25;
      } else if (targetInterval <= 50) {
        chartInterval = 50;
      } else if (targetInterval <= 100) {
        chartInterval = 100;
      } else if (targetInterval <= 250) {
        chartInterval = 250;
      } else if (targetInterval <= 500) {
        chartInterval = 500;
      } else {
        chartInterval = (targetInterval / 100).ceil() * 100.0;
      }
    }

    // Set finalMaxY to a round multiple of the interval with at least 20% room at the top
    double finalMaxY = ((rawMax * 1.2) / chartInterval).ceil() * chartInterval;
    if (finalMaxY <= 0) finalMaxY = chartInterval;

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
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 16 : 18,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: isCompact ? 180 : 250,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.success.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    );
                  },
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cardBg,
                    tooltipBorder: BorderSide(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String titleTooltip = labels[group.x.toInt()];
                      if (timePeriod == TimePeriod.month) {
                        final monthStr = DateFormat('MMM').format(now);
                        titleTooltip = '$monthStr $titleTooltip';
                      }

                      return BarTooltipItem(
                        '$titleTooltip\n',
                        TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${NumberFormat('#,##0.##', 'pt_BR').format(rod.toY)} kg',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
                      interval: 1, // Draw all, filter in getTitlesWidget
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }

                        // Smart Label Skip Logic
                        bool showLabel = false;
                        if (timePeriod == TimePeriod.week ||
                            timePeriod == TimePeriod.year ||
                            timePeriod == TimePeriod.allTime) {
                          showLabel = true;
                        } else if (timePeriod == TimePeriod.month) {
                          // Show 1, 5, 10, 15, 20, 25, 30
                          // index is 0-based (0 = Day 1)
                          if (index == 0 || (index + 1) % 5 == 0) {
                            showLabel = true;
                          }
                        }

                        if (!showLabel) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[index],
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: isCompact ? 8 : 10,
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
                      interval: chartInterval,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        // Skip values higher than finalMaxY to prevent edge labels
                        if (value > finalMaxY) return const SizedBox.shrink();

                        return Text(
                          '${_formatCompactNumber(value)} kg',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        width: timePeriod == TimePeriod.month
                            ? 6
                            : (timePeriod == TimePeriod.year ||
                                    timePeriod == TimePeriod.allTime
                                ? 10
                                : 14), // Thinner bars for month/year view
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                minY: 0,
                maxY: finalMaxY,
                alignment: BarChartAlignment.spaceAround,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${NumberFormat('#,##0.##', 'pt_BR').format(totalVolume)} kg',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: isCompact ? 9 : 11,
                    ),
              ),
              Text(
                'Avg: ${NumberFormat('#,##0.##', 'pt_BR').format(
                  // Average over non-zero days/months or just period length?
                  // Usually average per session is better, but here we show trend over time.
                  // Let's do average per active period unit (e.g. active days)
                  volumeData.where((v) => v > 0).isEmpty
                      ? 0.0
                      : volumeData.where((v) => v > 0).reduce((a, b) => a + b) /
                          volumeData.where((v) => v > 0).length,
                )} kg / active ${timePeriod == TimePeriod.year || timePeriod == TimePeriod.allTime ? 'mo' : 'day'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      fontSize: isCompact ? 9 : 11,
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
  final bool isCompact;

  const _WorkoutFrequencyCard({
    required this.sessions,
    required this.timePeriod,
    required this.referenceDate,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = referenceDate;
    const monthsShort = [
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

        final dayStartStr = mondayOfWeek.day.toString().padLeft(2, '0');
        final monthStartStr = monthsShort[mondayOfWeek.month - 1];
        final dayEndStr = sundayOfWeek.day.toString().padLeft(2, '0');
        final monthEndStr = monthsShort[sundayOfWeek.month - 1];

        title =
            'Workout Frequency ($dayStartStr $monthStartStr - $dayEndStr $monthEndStr)';
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

      case TimePeriod.allTime:
        // Group by Year (Show range from 2024 to current year + 1 for context)
        title = 'Workout Frequency (All Time)';
        final currentYear = DateTime.now().year;
        final yearsFromData = sessions.map((s) => s.effectiveDate.year).toList()
          ..sort();
        final firstDataYear =
            yearsFromData.isEmpty ? currentYear : yearsFromData.first;
        final lastDataYear =
            yearsFromData.isEmpty ? currentYear : yearsFromData.last;

        // Broaden range: start at 2024 (or earlier if data exists), end at currentYear + 1
        final firstYear = firstDataYear < 2024 ? firstDataYear : 2024;
        final lastYear =
            lastDataYear > currentYear ? lastDataYear : currentYear + 1;

        final range = lastYear - firstYear + 1;
        frequencyData = List.filled(range, 0);
        labels = List.generate(range, (i) => (firstYear + i).toString());

        for (var session in sessions) {
          final index = session.effectiveDate.year - firstYear;
          if (index >= 0 && index < range) {
            frequencyData[index]++;
          }
        }
        break;
    }

    // If weekly, use a consistency tracker instead of a bar chart
    if (timePeriod == TimePeriod.week) {
      return Container(
        padding: const EdgeInsets.all(16),
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
              style: (isCompact
                      ? Theme.of(context).textTheme.titleSmall
                      : Theme.of(context).textTheme.titleMedium)
                  ?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isActive =
                    index < frequencyData.length && frequencyData[index] > 0;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: isCompact ? 32 : 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.accent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? AppColors.accent
                                : AppColors.accent.withValues(alpha: 0.1),
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            isActive
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: isCompact ? 14 : 18,
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary.withValues(
                                    alpha: 0.3,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        index < labels.length ? labels[index] : '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: isCompact ? 8 : 10,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }

    final maxFreq = (frequencyData.isEmpty
            ? 0
            : frequencyData.reduce((a, b) => a > b ? a : b))
        .toDouble();
    final double maxYValue =
        timePeriod == TimePeriod.year || timePeriod == TimePeriod.allTime
            ? (maxFreq <= 25 ? 25 : (maxFreq / 5).ceil() * 5)
            : (maxFreq < 3 ? 3 : maxFreq + 1);

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < frequencyData.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: frequencyData[i].toDouble(),
              color: AppColors.accent,
              width: timePeriod == TimePeriod.year ||
                      timePeriod == TimePeriod.allTime
                  ? 12
                  : 22,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxYValue,
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
            style: (isCompact
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: isCompact ? 160 : 200,
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
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cardBg,
                    tooltipBorder: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} workouts',
                        const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
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
                      interval: timePeriod == TimePeriod.month &&
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: timePeriod == TimePeriod.year ||
                                              timePeriod == TimePeriod.allTime
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
                      interval: timePeriod == TimePeriod.month &&
                              frequencyData.length > 10
                          ? 5
                          : ((timePeriod == TimePeriod.year ||
                                  timePeriod == TimePeriod.allTime)
                              ? 5
                              : 1),
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                maxY: maxYValue,
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
  bool _isForwardAnimation = true;

  @override
  void didUpdateWidget(_TimePeriodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.referenceDate != oldWidget.referenceDate) {
      _isForwardAnimation = widget.referenceDate.isAfter(
        oldWidget.referenceDate,
      );
    }
  }

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
      case TimePeriod.allTime:
        return 'All Time';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
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
    // Add leading zero for single digit days
    final dayStr = date.day.toString().padLeft(2, '0');
    return '$dayStr ${months[date.month - 1]}';
  }

  String _monthName(int month) {
    const months = [
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
      case TimePeriod.allTime:
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
      case TimePeriod.allTime:
        break;
    }
  }

  bool _canNavigatePrevious(DateTime ref, DateTime now) {
    if (widget.selectedPeriod == TimePeriod.allTime) return false;
    switch (widget.selectedPeriod) {
      case TimePeriod.week:
        // Can always go back for weekly (like monthly)
        return true;
      case TimePeriod.month:
        return true; // Can always go back for month
      case TimePeriod.year:
        return true; // Can always go back for year
      case TimePeriod.allTime:
        return false;
    }
  }

  bool _canNavigateNext(DateTime ref, DateTime now) {
    if (widget.selectedPeriod == TimePeriod.allTime) return false;
    switch (widget.selectedPeriod) {
      case TimePeriod.week:
        // For weekly: next week must have started (weekStart <= today)
        final nextWeekStart = ref.add(const Duration(days: 7));
        final nowDate = DateTime(now.year, now.month, now.day);
        final nextWeekStartDate = DateTime(
          nextWeekStart.year,
          nextWeekStart.month,
          nextWeekStart.day,
        );
        return !nextWeekStartDate.isAfter(nowDate);
      case TimePeriod.month:
        return (ref.month < now.month && ref.year == now.year) ||
            ref.year < now.year;
      case TimePeriod.year:
        return ref.year < now.year;
      case TimePeriod.allTime:
        return false;
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        year.toString(),
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
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ref = widget.referenceDate;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Period Selector (Pills)
          Container(
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildPeriodTab(TimePeriod.week, 'Week'),
                _buildPeriodTab(TimePeriod.month, 'Month'),
                _buildPeriodTab(TimePeriod.year, 'Year'),
                _buildPeriodTab(TimePeriod.allTime, 'All Time'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Date Navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavButton(
                  onPressed: _canNavigatePrevious(ref, now)
                      ? () => _navigatePrevious(ref)
                      : null,
                  icon: Icons.chevron_left,
                ),
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
                        case TimePeriod.allTime:
                          break;
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final offset = Tween<Offset>(
                          begin: Offset(
                            _isForwardAnimation ? 0.2 : -0.2,
                            0.0,
                          ),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offset,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _getDisplayValue(ref),
                        key: ValueKey(
                          '${widget.selectedPeriod}_${_getDisplayValue(ref)}',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                _buildNavButton(
                  onPressed: _canNavigateNext(ref, now)
                      ? () => _navigateNext(ref, now)
                      : null,
                  icon: Icons.chevron_right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(TimePeriod period, String label) {
    final isSelected = widget.selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onPeriodChanged(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({VoidCallback? onPressed, required IconData icon}) {
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled
                ? AppColors.accent
                : AppColors.textTertiary.withValues(alpha: 0.3),
          ),
        ),
      ),
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
    for (int weekNum = 1;; weekNum++) {
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
                final weekStartDate = DateTime(
                  weekDate.year,
                  weekDate.month,
                  weekDate.day,
                );
                final weekEndDate = DateTime(
                  weekEnd.year,
                  weekEnd.month,
                  weekEnd.day,
                );
                final isSelected = refDate.isAfter(
                      weekStartDate.subtract(const Duration(days: 1)),
                    ) &&
                    refDate.isBefore(weekEndDate.add(const Duration(days: 1)));

                // Check if week is in the past or present (can be selected)
                final now = DateTime.now();

                // Can select if week has started (weekStart <= today)
                final nowDate = DateTime(now.year, now.month, now.day);
                final canSelectSimple = !weekStartDate.isAfter(nowDate);

                return GestureDetector(
                  onTap: canSelectSimple
                      ? () {
                          widget.onWeekSelected(weekDate);
                        }
                      : null,
                  child: Opacity(
                    opacity: canSelectSimple ? 1.0 : 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.accent : AppColors.inputBg,
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                final canSelect = (month <= widget.nowMonth &&
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
                        color:
                            isSelected ? AppColors.accent : AppColors.inputBg,
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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

/// Sticky Header Delegate for the Time Period Selector
class _StickySelectorDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickySelectorDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: SizedBox.expand(child: child),
    );
  }

  @override
  double get maxExtent => 112;
  @override
  double get minExtent => 112;
  @override
  bool shouldRebuild(covariant _StickySelectorDelegate oldDelegate) => true;
}

class _ExerciseFilterDialog extends StatefulWidget {
  final Map<String, PersonalRecord> allRecords;
  final Set<String> currentSelections;
  final Function(Set<String>) onApply;

  const _ExerciseFilterDialog({
    required this.allRecords,
    required this.currentSelections,
    required this.onApply,
  });

  @override
  State<_ExerciseFilterDialog> createState() => _ExerciseFilterDialogState();
}

class _ExerciseFilterDialogState extends State<_ExerciseFilterDialog> {
  late Set<String> _selectedExercises;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  String _formatCompactNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else {
      return number.toInt().toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedExercises = Set.from(
      widget.currentSelections.isEmpty
          ? widget.allRecords.keys
          : widget.currentSelections,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredExercises {
    final query = _searchController.text.toLowerCase();
    final allExercises = widget.allRecords.keys.toList();
    if (query.isEmpty) return allExercises;
    return allExercises.where((e) => e.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredExercises;
    final totalPages = (filteredList.length / _itemsPerPage).ceil();

    // Ensure current page is valid
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = 0;
    }

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < filteredList.length)
        ? startIndex + _itemsPerPage
        : filteredList.length;

    final currentItems = filteredList.isEmpty
        ? <String>[]
        : filteredList.sublist(startIndex, endIndex);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.cardBg,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Exercises',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (_) {
                setState(() {
                  _currentPage = 0; // Reset pagination on search
                });
              },
            ),
            const SizedBox(height: 16),

            // Selection Controls
            Row(
              children: [
                if (filteredList.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // Select all currently filtered visible items?
                        // Or all filtered? Let's do all filtered for convenience
                        _selectedExercises.addAll(_filteredExercises);
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text('Select All'),
                  ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedExercises.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    alignment: Alignment.centerLeft,
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Clear All'),
                ),
                const Spacer(),
                Text(
                  '${_selectedExercises.length} selected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const Divider(),

            // List
            Expanded(
              child: currentItems.isEmpty
                  ? Center(
                      child: Text(
                        'No exercises found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: currentItems.length,
                      itemBuilder: (context, index) {
                        final exercise = currentItems[index];
                        final weight = widget.allRecords[exercise] ??
                            const PersonalRecord();
                        final isSelected = _selectedExercises.contains(
                          exercise,
                        );

                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            exercise,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Heavy: ${weight.maxWeight.toStringAsFixed(1)}kg x ${weight.maxWeightReps} • Vol: ${_formatCompactNumber(weight.maxVolume)} ${weight.maxVolumeBreakdown}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          value: isSelected,
                          activeColor: AppColors.accent,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedExercises.add(exercise);
                              } else {
                                _selectedExercises.remove(exercise);
                              }
                            });
                          },
                          dense: true,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            // Pagination Controls
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${_currentPage + 1} / $totalPages',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedExercises.isEmpty
                      ? null
                      : () {
                          widget.onApply(_selectedExercises);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PRSharePreview extends StatelessWidget {
  final Map<String, PersonalRecord> records;

  const _PRSharePreview({required this.records});

  String _formatNumber(double num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
    }
    return NumberFormat('#,##0.##', 'pt_BR').format(num);
  }

  @override
  Widget build(BuildContext context) {
    // Fixed 9:16 resolution for Instagram Stories
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(color: Color(0xFF0B0F14)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: Container(
              width: 960, // 1080 - 120 padding
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: const Color(0xFF141A21),
                borderRadius: BorderRadius.circular(48),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 60,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER / BRANDING =====
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: AppColors.accent,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'LIFTLY',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                fontSize: 32,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'PERSONAL RECORDS',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  fontSize: 14,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),

                  // ===== RECORDS GRID =====
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: records.entries.map((entry) {
                      return Container(
                        width: 400, // Fits 2 columns (400*2 + 24 = 824 < 960)
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    fontSize: 16,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            _buildCompactRow(
                              context,
                              'Heaviest',
                              entry.value.maxWeight,
                              'kg',
                              reps: entry.value.maxWeightReps,
                            ),
                            const SizedBox(height: 8),
                            _buildCompactRow(
                              context,
                              'Best Vol',
                              entry.value.maxVolume,
                              'kg',
                              details: entry.value.maxVolumeBreakdown,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 48),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    thickness: 1.5,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Track your progress with Liftly',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    letterSpacing: 1,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'liftly.app',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.accent.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(
    BuildContext context,
    String label,
    double value,
    String unit, {
    int? reps,
    String? details,
    int maxLines = 1,
  }) {
    final repsStr = reps != null ? 'x $reps' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                _formatNumber(value),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (repsStr.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  repsStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (details != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '($details)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
