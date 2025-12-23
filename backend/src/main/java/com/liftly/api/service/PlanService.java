package com.liftly.api.service;

import com.liftly.api.dto.CreatePlanRequest;
import com.liftly.api.dto.PlanResponse;
import com.liftly.api.entity.Plan;
import com.liftly.api.entity.PlanExercise;
import com.liftly.api.entity.User;
import com.liftly.api.exception.AuthenticationException;
import com.liftly.api.repository.PlanRepository;
import com.liftly.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PlanService {
    private final PlanRepository planRepository;
    private final UserRepository userRepository;

    public PlanResponse createPlan(Long userId, CreatePlanRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthenticationException("User not found"));

        Plan plan = new Plan();
        plan.setUser(user);
        plan.setName(request.getName());
        plan.setDescription(request.getDescription());

        // Add exercises
        if (request.getExercises() != null && !request.getExercises().isEmpty()) {
            List<PlanExercise> exercises = request.getExercises().stream()
                    .map((exerciseName) -> {
                        PlanExercise exercise = new PlanExercise();
                        exercise.setName(exerciseName);
                        exercise.setOrder(request.getExercises().indexOf(exerciseName));
                        exercise.setPlan(plan);
                        return exercise;
                    })
                    .collect(Collectors.toList());
            plan.setExercises(exercises);
        }

        Plan savedPlan = planRepository.save(plan);
        return mapToPlanResponse(savedPlan);
    }

    public List<PlanResponse> getPlansByUserId(Long userId) {
        List<Plan> plans = planRepository.findByUserId(userId);
        return plans.stream()
                .map(this::mapToPlanResponse)
                .collect(Collectors.toList());
    }

    public PlanResponse getPlanById(Long userId, Long planId) {
        Plan plan = planRepository.findByIdAndUserId(planId, userId);
        if (plan == null) {
            throw new AuthenticationException("Plan not found");
        }
        return mapToPlanResponse(plan);
    }

    public PlanResponse updatePlan(Long userId, Long planId, CreatePlanRequest request) {
        Plan plan = planRepository.findByIdAndUserId(planId, userId);
        if (plan == null) {
            throw new AuthenticationException("Plan not found");
        }

        plan.setName(request.getName());
        plan.setDescription(request.getDescription());

        // Clear and update exercises
        plan.getExercises().clear();
        if (request.getExercises() != null && !request.getExercises().isEmpty()) {
            List<PlanExercise> exercises = request.getExercises().stream()
                    .map((exerciseName) -> {
                        PlanExercise exercise = new PlanExercise();
                        exercise.setName(exerciseName);
                        exercise.setOrder(request.getExercises().indexOf(exerciseName));
                        exercise.setPlan(plan);
                        return exercise;
                    })
                    .collect(Collectors.toList());
            plan.setExercises(exercises);
        }

        Plan updatedPlan = planRepository.save(plan);
        return mapToPlanResponse(updatedPlan);
    }

    public void deletePlan(Long userId, Long planId) {
        Plan plan = planRepository.findByIdAndUserId(planId, userId);
        if (plan == null) {
            throw new AuthenticationException("Plan not found");
        }
        planRepository.delete(plan);
    }

    private PlanResponse mapToPlanResponse(Plan plan) {
        PlanResponse response = new PlanResponse();
        response.setId(plan.getId());
        response.setUserId(plan.getUser().getId());
        response.setName(plan.getName());
        response.setDescription(plan.getDescription());
        response.setCreatedAt(plan.getCreatedAt());
        response.setUpdatedAt(plan.getUpdatedAt());

        if (plan.getExercises() != null) {
            response.setExercises(
                    plan.getExercises().stream()
                            .map(ex -> new PlanResponse.PlanExerciseResponse(
                                    ex.getId(),
                                    ex.getName(),
                                    ex.getOrder()
                            ))
                            .collect(Collectors.toList())
            );
        }

        return response;
    }
}
