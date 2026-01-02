import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';

// Full page skeleton
class StatsPageShimmer extends StatelessWidget {
  const StatsPageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), elevation: 0),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Time Period Selector Shimmer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    // Segmented Control (Tabs)
                    Row(
                      children: [
                        Expanded(
                          child: Shimmer.fromColors(
                            baseColor: const Color(0xFF2A2A2A),
                            highlightColor: const Color(0xFF404040),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Shimmer.fromColors(
                              baseColor: const Color(0xFF2A2A2A),
                              highlightColor: const Color(0xFF404040),
                              child: Container(
                                width: 50,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Shimmer.fromColors(
                              baseColor: const Color(0xFF2A2A2A),
                              highlightColor: const Color(0xFF404040),
                              child: Container(
                                width: 50,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Date Navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Shimmer.fromColors(
                            baseColor: const Color(0xFF2A2A2A),
                            highlightColor: const Color(0xFF404040),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                          ),
                          Shimmer.fromColors(
                            baseColor: const Color(0xFF2A2A2A),
                            highlightColor: const Color(0xFF404040),
                            child: Container(
                              width: 140,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Shimmer.fromColors(
                            baseColor: const Color(0xFF2A2A2A),
                            highlightColor: const Color(0xFF404040),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Use separate partial content shimmer
              const StatsContentShimmer(),
            ],
          ),
        ),
      ),
    );
  }
}

// Partial skeleton (Body only)
class StatsContentShimmer extends StatelessWidget {
  const StatsContentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 36,
        ), // Added spacing here for consistent startup/partial load
        // Overview Section Header
        Shimmer.fromColors(
          baseColor: const Color(0xFF2A2A2A),
          highlightColor: const Color(0xFF404040),
          child: Container(
            width: 100,
            height: 28, // Title Large size
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Overview Grid (3 small boxes) - Matches Aspect Ratio 1.0 roughly
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildAnalysisBoxShimmer(),
            _buildAnalysisBoxShimmer(),
            _buildAnalysisBoxShimmer(),
          ],
        ),

        const SizedBox(height: 32),

        // Trends Section
        Shimmer.fromColors(
          baseColor: const Color(0xFF2A2A2A),
          highlightColor: const Color(0xFF404040),
          child: Container(
            width: 80,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Volume Chart Card Shimmer (Matches _VolumeChartCard structure)
        Container(
          width: double.infinity,
          height: 300, // Approx height of _VolumeChartCard
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF2A2A2A),
            highlightColor: const Color(0xFF404040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 24, color: Colors.white),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      7,
                      (index) => Container(
                        width: 14, // Matches bar width
                        height: 50 + (index * 25.0) % 150, // Random heights
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 80, height: 12, color: Colors.white),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Frequency Card Shimmer (Matches _WorkoutFrequencyCard)
        Container(
          width: double.infinity,
          height: 300, // Approx height including title and chart
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF2A2A2A),
            highlightColor: const Color(0xFF404040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 200, height: 24, color: Colors.white),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      7,
                      (index) => Container(
                        width: 12,
                        height: 30 + (index * 20.0) % 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Personal Records Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Shimmer.fromColors(
              baseColor: const Color(0xFF2A2A2A),
              highlightColor: const Color(0xFF404040),
              child: Container(
                width: 160,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Shimmer.fromColors(
              baseColor: const Color(0xFF2A2A2A),
              highlightColor: const Color(0xFF404040),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // PR List Items
        _buildPRCardShimmer(),
        const SizedBox(height: 12),
        _buildPRCardShimmer(),
      ],
    );
  }

  Widget _buildAnalysisBoxShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(12),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF2A2A2A),
        highlightColor: const Color(0xFF404040),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 6),
            Container(width: 40, height: 20, color: Colors.white), // Value
            const SizedBox(height: 4),
            Container(width: 30, height: 10, color: Colors.white), // Label
          ],
        ),
      ),
    );
  }

  Widget _buildPRCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF2A2A2A),
        highlightColor: const Color(0xFF404040),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 16, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 80, height: 12, color: Colors.white),
              ],
            ),
            Container(
              width: 60,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
