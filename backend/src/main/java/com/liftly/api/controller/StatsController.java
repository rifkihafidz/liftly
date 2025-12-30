package com.liftly.api.controller;

import com.liftly.api.dto.ApiResponse;
import com.liftly.api.dto.StatsRequest;
import com.liftly.api.dto.StatsResponse;
import com.liftly.api.service.StatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/stats")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StatsController {
    private final StatsService statsService;

    /**
     * Get comprehensive stats summary for a user within date range
     * Returns all data needed for stats page/dashboard
     * POST /stats/summary
     * Body: { "userId": 1, "startDate": "2025-12-21", "endDate": "2025-12-28" }
     */
    @PostMapping("/summary")
    public ResponseEntity<ApiResponse<StatsResponse>> getStatsSummary(@RequestBody StatsRequest request) {
        try {
            // Convert LocalDate to LocalDateTime (start of day to end of day)
            LocalDateTime startDateTime = request.getStartDate().atStartOfDay();
            LocalDateTime endDateTime = request.getEndDate().atTime(23, 59, 59);
            
            StatsResponse summary = statsService.getStatsSummary(request.getUserId(), startDateTime, endDateTime);
            return ResponseEntity.ok(ApiResponse.success(summary, "Stats summary retrieved successfully", HttpStatus.OK.value()));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(ApiResponse.error(e.getMessage(), HttpStatus.BAD_REQUEST.value()));
        }
    }

    /**
     * Get total volume for user within date range
     * GET /stats/volume?userId={userId}&startDate={ISO_DATE}&endDate={ISO_DATE}
     */
    @GetMapping("/volume")
    public ResponseEntity<ApiResponse<Double>> getTotalVolume(
            @RequestParam Long userId,
            @RequestParam LocalDateTime startDate,
            @RequestParam LocalDateTime endDate) {
        try {
            Double volume = statsService.getTotalVolume(userId, startDate, endDate);
            return ResponseEntity.ok(ApiResponse.success(volume, "Total volume retrieved successfully", HttpStatus.OK.value()));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(ApiResponse.error(e.getMessage(), HttpStatus.BAD_REQUEST.value()));
        }
    }

    /**
     * Get personal records (max weight per exercise)
     * GET /stats/personal-records?userId={userId}
     */
    @GetMapping("/personal-records")
    public ResponseEntity<ApiResponse<Map<String, Double>>> getPersonalRecords(
            @RequestParam Long userId) {
        try {
            Map<String, Double> records = statsService.getPersonalRecords(userId);
            return ResponseEntity.ok(ApiResponse.success(records, "Personal records retrieved successfully", HttpStatus.OK.value()));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(ApiResponse.error(e.getMessage(), HttpStatus.BAD_REQUEST.value()));
        }
    }

    /**
     * Get exercise volume distribution within date range
     * GET /stats/exercise-volume?userId={userId}&startDate={ISO_DATE}&endDate={ISO_DATE}
     */
    @GetMapping("/exercise-volume")
    public ResponseEntity<ApiResponse<Map<String, Double>>> getExerciseVolume(
            @RequestParam Long userId,
            @RequestParam LocalDateTime startDate,
            @RequestParam LocalDateTime endDate) {
        try {
            Map<String, Double> volumes = statsService.getExerciseVolume(userId, startDate, endDate);
            return ResponseEntity.ok(ApiResponse.success(volumes, "Exercise volume retrieved successfully", HttpStatus.OK.value()));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(ApiResponse.error(e.getMessage(), HttpStatus.BAD_REQUEST.value()));
        }
    }

    /**
     * Get average workout duration within date range (in minutes)
     * GET /stats/average-duration?userId={userId}&startDate={ISO_DATE}&endDate={ISO_DATE}
     */
    @GetMapping("/average-duration")
    public ResponseEntity<ApiResponse<Integer>> getAverageDuration(
            @RequestParam Long userId,
            @RequestParam LocalDateTime startDate,
            @RequestParam LocalDateTime endDate) {
        try {
            Integer duration = statsService.getAverageDuration(userId, startDate, endDate);
            return ResponseEntity.ok(ApiResponse.success(duration, "Average duration retrieved successfully", HttpStatus.OK.value()));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(ApiResponse.error(e.getMessage(), HttpStatus.BAD_REQUEST.value()));
        }
    }

    /**
     * Get workout count within date range
     * GET /stats/workout-count?userId={userId}&startDate={ISO_DATE}&endDate={ISO_DATE}
     */
    @GetMapping("/workout-count")
    public ResponseEntity<ApiResponse<Integer>> getWorkoutCount(
            @RequestParam Long userId,
            @RequestParam LocalDateTime startDate,
            @RequestParam LocalDateTime endDate) {
        try {
            Integer count = statsService.getWorkoutCount(userId, startDate, endDate);
            return ResponseEntity.ok(ApiResponse.success(count, "Workout count retrieved successfully", HttpStatus.OK.value()));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(ApiResponse.error(e.getMessage(), HttpStatus.BAD_REQUEST.value()));
        }
    }

    /**
     * Get top exercises by volume within date range
     * GET /stats/top-exercises?userId={userId}&startDate={ISO_DATE}&endDate={ISO_DATE}&limit={limit}
     */
    @GetMapping("/top-exercises")
    public ResponseEntity<ApiResponse<Map<String, Double>>> getTopExercises(
            @RequestParam Long userId,
            @RequestParam LocalDateTime startDate,
            @RequestParam LocalDateTime endDate,
            @RequestParam(defaultValue = "10") int limit) {
        try {
            Map<String, Double> topExercises = statsService.getTopExercisesByVolume(userId, startDate, endDate, limit);
            return ResponseEntity.ok(ApiResponse.success(topExercises, "Top exercises retrieved successfully", HttpStatus.OK.value()));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(ApiResponse.error(e.getMessage(), HttpStatus.BAD_REQUEST.value()));
        }
    }
}
