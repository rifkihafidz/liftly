package com.liftly.api.service;

import com.liftly.api.dto.StatsResponse;
import com.liftly.api.dto.WorkoutResponse;
import com.liftly.api.entity.*;
import com.liftly.api.exception.AuthenticationException;
import com.liftly.api.repository.WorkoutRepository;
import com.liftly.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StatsService {
    private final WorkoutRepository workoutRepository;
    private final UserRepository userRepository;
    private final WorkoutService workoutService;

    /**
     * Get comprehensive stats summary for a user within a date range
     * Returns all data needed for stats page in a single response
     */
    public StatsResponse getStatsSummary(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        verifyUserExists(userId);
        
        List<Workout> workouts = workoutRepository.findByUserIdAndWorkoutDateBetween(
            userId, startDate, endDate
        );
        
        // Convert workouts to responses for chart data
        List<WorkoutResponse> workoutResponses = workouts.stream()
            .map(workoutService::mapToWorkoutResponse)
            .collect(Collectors.toList());
        
        // Build comprehensive response
        StatsResponse response = new StatsResponse();
        response.setWorkouts(workoutResponses);
        response.setWorkoutCount(getWorkoutCount(userId, startDate, endDate));
        response.setTotalVolume(calculateTotalVolume(workouts));
        response.setAverageDurationMinutes(getAverageDuration(userId, startDate, endDate));
        response.setPersonalRecords(getPersonalRecords(userId));
        response.setTopExercisesByVolume(getTopExercisesByVolume(userId, startDate, endDate, 10));
        response.setPeriodStart(startDate.toString());
        response.setPeriodEnd(endDate.toString());
        
        return response;
    }

    /**
     * Get total volume (sum of all weight * reps) for a user within a date range
     */
    public Double getTotalVolume(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        verifyUserExists(userId);
        
        List<Workout> workouts = workoutRepository.findByUserIdAndWorkoutDateBetween(
            userId, startDate, endDate
        );
        
        return calculateTotalVolume(workouts);
    }

    /**
     * Get personal records (maximum weight per exercise) for a user
     */
    public Map<String, Double> getPersonalRecords(Long userId) {
        verifyUserExists(userId);
        
        List<Workout> workouts = workoutRepository.findByUserId(userId);
        Map<String, Double> records = new HashMap<>();
        
        for (Workout workout : workouts) {
            for (WorkoutExercise exercise : workout.getExercises()) {
                if (exercise.getSkipped()) continue;
                
                for (WorkoutSet set : exercise.getSets()) {
                    for (SetSegment segment : set.getSegments()) {
                        String exerciseName = exercise.getName();
                        double currentMax = records.getOrDefault(exerciseName, 0.0);
                        records.put(exerciseName, Math.max(currentMax, segment.getWeight()));
                    }
                }
            }
        }
        
        // Sort by value descending
        return records.entrySet().stream()
            .sorted((a, b) -> b.getValue().compareTo(a.getValue()))
            .collect(Collectors.toMap(
                Map.Entry::getKey,
                Map.Entry::getValue,
                (e1, e2) -> e1,
                LinkedHashMap::new
            ));
    }

    /**
     * Get exercise volume (total volume per exercise) within a date range
     */
    public Map<String, Double> getExerciseVolume(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        verifyUserExists(userId);
        
        List<Workout> workouts = workoutRepository.findByUserIdAndWorkoutDateBetween(
            userId, startDate, endDate
        );
        
        Map<String, Double> exerciseVolumes = new HashMap<>();
        
        for (Workout workout : workouts) {
            for (WorkoutExercise exercise : workout.getExercises()) {
                if (exercise.getSkipped()) continue;
                
                for (WorkoutSet set : exercise.getSets()) {
                    for (SetSegment segment : set.getSegments()) {
                        String exerciseName = exercise.getName();
                        double volume = segment.getWeight() * (segment.getRepsTo() - segment.getRepsFrom() + 1);
                        double currentVolume = exerciseVolumes.getOrDefault(exerciseName, 0.0);
                        exerciseVolumes.put(exerciseName, currentVolume + volume);
                    }
                }
            }
        }
        
        // Sort by value descending
        return exerciseVolumes.entrySet().stream()
            .sorted((a, b) -> b.getValue().compareTo(a.getValue()))
            .collect(Collectors.toMap(
                Map.Entry::getKey,
                Map.Entry::getValue,
                (e1, e2) -> e1,
                LinkedHashMap::new
            ));
    }

    /**
     * Get average workout duration (in minutes) for a user within a date range
     */
    public Integer getAverageDuration(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        verifyUserExists(userId);
        
        List<Workout> workouts = workoutRepository.findByUserIdAndWorkoutDateBetween(
            userId, startDate, endDate
        );
        
        if (workouts.isEmpty()) {
            return 0;
        }
        
        List<Long> durations = workouts.stream()
            .filter(w -> w.getStartedAt() != null && w.getEndedAt() != null)
            .map(w -> {
                long millis = w.getEndedAt().toLocalTime().toNanoOfDay() - 
                             w.getStartedAt().toLocalTime().toNanoOfDay();
                return millis / (1000 * 1000 * 60); // Convert to minutes
            })
            .collect(Collectors.toList());
        
        if (durations.isEmpty()) {
            return 0;
        }
        
        return (int) (durations.stream()
            .mapToLong(Long::longValue)
            .sum() / durations.size());
    }

    /**
     * Get workout frequency (count) for a user within a date range
     */
    public Integer getWorkoutCount(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        verifyUserExists(userId);
        
        List<Workout> workouts = workoutRepository.findByUserIdAndWorkoutDateBetween(
            userId, startDate, endDate
        );
        
        return workouts.size();
    }

    /**
     * Get top exercises by volume within a date range (sorted by volume)
     */
    public Map<String, Double> getTopExercisesByVolume(Long userId, LocalDateTime startDate, LocalDateTime endDate, int limit) {
        Map<String, Double> exerciseVolumes = getExerciseVolume(userId, startDate, endDate);
        
        return exerciseVolumes.entrySet().stream()
            .limit(limit)
            .collect(Collectors.toMap(
                Map.Entry::getKey,
                Map.Entry::getValue,
                (e1, e2) -> e1,
                LinkedHashMap::new
            ));
    }

    /**
     * Helper: Calculate total volume from list of workouts
     */
    private Double calculateTotalVolume(List<Workout> workouts) {
        double total = 0.0;
        
        for (Workout workout : workouts) {
            for (WorkoutExercise exercise : workout.getExercises()) {
                if (exercise.getSkipped()) continue;
                
                for (WorkoutSet set : exercise.getSets()) {
                    for (SetSegment segment : set.getSegments()) {
                        double volume = segment.getWeight() * (segment.getRepsTo() - segment.getRepsFrom() + 1);
                        total += volume;
                    }
                }
            }
        }
        
        return total;
    }

    /**
     * Helper: Verify user exists
     */
    private void verifyUserExists(Long userId) {
        userRepository.findById(userId)
            .orElseThrow(() -> new AuthenticationException("User not found"));
    }
}
