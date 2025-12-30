package com.liftly.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;
import java.util.Map;

/**
 * Comprehensive stats response for a user within a date range
 * Contains all data needed for stats page/dashboard
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StatsResponse {
    // Workout data for charts
    private List<WorkoutResponse> workouts;
    
    // Summary metrics
    private Integer workoutCount;
    private Double totalVolume;
    private Integer averageDurationMinutes;
    
    // Rankings
    private Map<String, Double> personalRecords;
    private Map<String, Double> topExercisesByVolume;
    
    // Metadata
    private String periodStart;
    private String periodEnd;
}
