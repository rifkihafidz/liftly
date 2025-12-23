package com.liftly.api.controller;

import com.liftly.api.dto.ApiResponse;
import com.liftly.api.dto.CreatePlanRequest;
import com.liftly.api.dto.PlanResponse;
import com.liftly.api.service.PlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/plans")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class PlanController {
    private final PlanService planService;

    @PostMapping
    public ResponseEntity<ApiResponse<PlanResponse>> createPlan(
            @RequestParam Long userId,
            @Valid @RequestBody CreatePlanRequest request) {
        PlanResponse response = planService.createPlan(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Plan created successfully", HttpStatus.CREATED.value()));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<PlanResponse>>> getPlans(@RequestParam Long userId) {
        List<PlanResponse> plans = planService.getPlansByUserId(userId);
        return ResponseEntity.ok(ApiResponse.success(plans, "Plans retrieved successfully", HttpStatus.OK.value()));
    }

    @GetMapping("/{planId}")
    public ResponseEntity<ApiResponse<PlanResponse>> getPlan(
            @PathVariable Long planId,
            @RequestParam Long userId) {
        PlanResponse plan = planService.getPlanById(userId, planId);
        return ResponseEntity.ok(ApiResponse.success(plan, "Plan retrieved successfully", HttpStatus.OK.value()));
    }

    @PutMapping("/{planId}")
    public ResponseEntity<ApiResponse<PlanResponse>> updatePlan(
            @PathVariable Long planId,
            @RequestParam Long userId,
            @Valid @RequestBody CreatePlanRequest request) {
        PlanResponse response = planService.updatePlan(userId, planId, request);
        return ResponseEntity.ok(ApiResponse.success(response, "Plan updated successfully", HttpStatus.OK.value()));
    }

    @DeleteMapping("/{planId}")
    public ResponseEntity<ApiResponse<?>> deletePlan(
            @PathVariable Long planId,
            @RequestParam Long userId) {
        planService.deletePlan(userId, planId);
        return ResponseEntity.ok(ApiResponse.success(null, "Plan deleted successfully", HttpStatus.OK.value()));
    }
}
