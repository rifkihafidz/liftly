package com.liftly.api.controller;

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
    public ResponseEntity<PlanResponse> createPlan(
            @RequestParam Long userId,
            @Valid @RequestBody CreatePlanRequest request) {
        PlanResponse response = planService.createPlan(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<PlanResponse>> getPlans(@RequestParam Long userId) {
        List<PlanResponse> plans = planService.getPlansByUserId(userId);
        return ResponseEntity.ok(plans);
    }

    @GetMapping("/{planId}")
    public ResponseEntity<PlanResponse> getPlan(
            @PathVariable Long planId,
            @RequestParam Long userId) {
        PlanResponse plan = planService.getPlanById(userId, planId);
        return ResponseEntity.ok(plan);
    }

    @PutMapping("/{planId}")
    public ResponseEntity<PlanResponse> updatePlan(
            @PathVariable Long planId,
            @RequestParam Long userId,
            @Valid @RequestBody CreatePlanRequest request) {
        PlanResponse response = planService.updatePlan(userId, planId, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{planId}")
    public ResponseEntity<String> deletePlan(
            @PathVariable Long planId,
            @RequestParam Long userId) {
        planService.deletePlan(userId, planId);
        return ResponseEntity.ok("Plan deleted successfully");
    }
}
