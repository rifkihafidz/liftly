package com.liftly.api.controller;

import com.liftly.api.dto.ApiResponse;
import com.liftly.api.dto.CreateWorkoutRequest;
import com.liftly.api.dto.WorkoutResponse;
import com.liftly.api.service.WorkoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/workouts")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class WorkoutController {
    private final WorkoutService workoutService;

    @PostMapping
    public ResponseEntity<ApiResponse<WorkoutResponse>> createWorkout(
            @RequestParam Long userId,
            @Valid @RequestBody CreateWorkoutRequest request) {
        WorkoutResponse response = workoutService.createWorkout(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Workout logged successfully", HttpStatus.CREATED.value()));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<WorkoutResponse>>> getWorkouts(@RequestParam Long userId) {
        List<WorkoutResponse> workouts = workoutService.getWorkoutsByUserId(userId);
        return ResponseEntity.ok(ApiResponse.success(workouts, "Workouts retrieved successfully", HttpStatus.OK.value()));
    }

    @GetMapping("/{workoutId}")
    public ResponseEntity<ApiResponse<WorkoutResponse>> getWorkout(
            @PathVariable Long workoutId,
            @RequestParam Long userId) {
        WorkoutResponse workout = workoutService.getWorkoutById(userId, workoutId);
        return ResponseEntity.ok(ApiResponse.success(workout, "Workout retrieved successfully", HttpStatus.OK.value()));
    }

    @PutMapping("/{workoutId}")
    public ResponseEntity<ApiResponse<WorkoutResponse>> updateWorkout(
            @PathVariable Long workoutId,
            @RequestParam Long userId,
            @Valid @RequestBody CreateWorkoutRequest request) {
        WorkoutResponse response = workoutService.updateWorkout(userId, workoutId, request);
        return ResponseEntity.ok(ApiResponse.success(response, "Workout updated successfully", HttpStatus.OK.value()));
    }

    @DeleteMapping("/{workoutId}")
    public ResponseEntity<ApiResponse<?>> deleteWorkout(
            @PathVariable Long workoutId,
            @RequestParam Long userId) {
        workoutService.deleteWorkout(userId, workoutId);
        return ResponseEntity.ok(ApiResponse.success(null, "Workout deleted successfully", HttpStatus.OK.value()));
    }
}
