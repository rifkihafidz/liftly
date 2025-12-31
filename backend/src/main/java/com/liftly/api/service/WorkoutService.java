package com.liftly.api.service;

import com.liftly.api.dto.CreateWorkoutRequest;
import com.liftly.api.dto.WorkoutResponse;
import com.liftly.api.entity.*;
import com.liftly.api.exception.AuthenticationException;
import com.liftly.api.repository.WorkoutRepository;
import com.liftly.api.repository.UserRepository;
import com.liftly.api.repository.PlanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WorkoutService {
    private final WorkoutRepository workoutRepository;
    private final UserRepository userRepository;
    private final PlanRepository planRepository;

    public WorkoutResponse createWorkout(Long userId, CreateWorkoutRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthenticationException("User not found"));

        Workout workout = new Workout();
        workout.setUser(user);
        // Convert LocalDate to LocalDateTime (start of day)
        workout.setWorkoutDate(request.getWorkoutDate().atStartOfDay());
        
        // Combine workout date with time components
        if (request.getStartedAt() != null) {
            workout.setStartedAt(
                request.getWorkoutDate().atTime(
                    request.getStartedAt().getHour(),
                    request.getStartedAt().getMinute(),
                    request.getStartedAt().getSecond()
                )
            );
        }
        
        if (request.getEndedAt() != null) {
            workout.setEndedAt(
                request.getWorkoutDate().atTime(
                    request.getEndedAt().getHour(),
                    request.getEndedAt().getMinute(),
                    request.getEndedAt().getSecond()
                )
            );
        }

        // Set plan if provided
        if (request.getPlanId() != null) {
            Plan plan = planRepository.findByIdAndUserId(request.getPlanId(), userId);
            if (plan == null) {
                throw new AuthenticationException("Plan not found");
            }
            workout.setPlan(plan);
        }

        // Add exercises with sets and segments
        if (request.getExercises() != null && !request.getExercises().isEmpty()) {
            List<WorkoutExercise> exercises = request.getExercises().stream()
                    .map(exRequest -> {
                        WorkoutExercise exercise = new WorkoutExercise();
                        exercise.setWorkout(workout);
                        exercise.setName(exRequest.getName());
                        exercise.setOrder(exRequest.getOrder());
                        exercise.setSkipped(exRequest.getSkipped() != null ? exRequest.getSkipped() : false);

                        // Add sets
                        if (exRequest.getSets() != null && !exRequest.getSets().isEmpty()) {
                            List<WorkoutSet> sets = exRequest.getSets().stream()
                                    .map(setRequest -> {
                                        WorkoutSet set = new WorkoutSet();
                                        set.setExercise(exercise);
                                        set.setSetNumber(setRequest.getSetNumber());

                                        // Add segments
                                        if (setRequest.getSegments() != null && !setRequest.getSegments().isEmpty()) {
                                            List<SetSegment> segments = setRequest.getSegments().stream()
                                                    .map(segRequest -> {
                                                        SetSegment segment = new SetSegment();
                                                        segment.setSet(set);
                                                        segment.setWeight(segRequest.getWeight());
                                                        segment.setRepsFrom(segRequest.getRepsFrom());
                                                        segment.setRepsTo(segRequest.getRepsTo());
                                                        segment.setSegmentOrder(segRequest.getSegmentOrder());
                                                        segment.setNotes(segRequest.getNotes());
                                                        return segment;
                                                    })
                                                    .collect(Collectors.toList());
                                            set.setSegments(segments);
                                        }
                                        return set;
                                    })
                                    .collect(Collectors.toList());
                            exercise.setSets(sets);
                        }
                        return exercise;
                    })
                    .collect(Collectors.toList());
            workout.setExercises(exercises);
        }

        Workout savedWorkout = workoutRepository.save(workout);
        return mapToWorkoutResponse(savedWorkout);
    }

    public List<WorkoutResponse> getWorkoutsByUserId(Long userId) {
        List<Workout> workouts = workoutRepository.findByUserIdOrderByWorkoutDateDesc(userId);
        return workouts.stream()
                .map(this::mapToWorkoutResponse)
                .collect(Collectors.toList());
    }

    public WorkoutResponse getWorkoutById(Long userId, Long workoutId) {
        Workout workout = workoutRepository.findByIdAndUserId(workoutId, userId);
        if (workout == null) {
            throw new AuthenticationException("Workout not found");
        }
        return mapToWorkoutResponse(workout);
    }

    public void deleteWorkout(Long userId, Long workoutId) {
        Workout workout = workoutRepository.findByIdAndUserId(workoutId, userId);
        if (workout == null) {
            throw new AuthenticationException("Workout not found");
        }
        workoutRepository.delete(workout);
    }

    public WorkoutResponse updateWorkout(Long userId, Long workoutId, CreateWorkoutRequest request) {
        userRepository.findById(userId)
                .orElseThrow(() -> new AuthenticationException("User not found"));

        Workout workout = workoutRepository.findByIdAndUserId(workoutId, userId);
        if (workout == null) {
            throw new AuthenticationException("Workout not found");
        }

        // Update basic fields
        // Convert LocalDate to LocalDateTime (start of day)
        workout.setWorkoutDate(request.getWorkoutDate().atStartOfDay());
        
        // Combine workout date with time components
        if (request.getStartedAt() != null) {
            workout.setStartedAt(
                request.getWorkoutDate().atTime(
                    request.getStartedAt().getHour(),
                    request.getStartedAt().getMinute(),
                    request.getStartedAt().getSecond()
                )
            );
        }
        
        if (request.getEndedAt() != null) {
            workout.setEndedAt(
                request.getWorkoutDate().atTime(
                    request.getEndedAt().getHour(),
                    request.getEndedAt().getMinute(),
                    request.getEndedAt().getSecond()
                )
            );
        }

        // Update plan if provided
        if (request.getPlanId() != null) {
            Plan plan = planRepository.findByIdAndUserId(request.getPlanId(), userId);
            if (plan == null) {
                throw new AuthenticationException("Plan not found");
            }
            workout.setPlan(plan);
        } else {
            workout.setPlan(null);
        }

        // Handle exercises
        if (request.getExercises() != null && !request.getExercises().isEmpty()) {
            // Process each exercise in request
            for (CreateWorkoutRequest.WorkoutExerciseRequest exRequest : request.getExercises()) {
                if (exRequest.getId() != null) {
                    // Update existing exercise
                    for (WorkoutExercise exercise : workout.getExercises()) {
                        if (exercise.getId().equals(exRequest.getId())) {
                            exercise.setName(exRequest.getName());
                            exercise.setOrder(exRequest.getOrder());
                            exercise.setSkipped(exRequest.getSkipped() != null ? exRequest.getSkipped() : false);
                            updateExerciseSets(exercise, exRequest.getSets());
                            break;
                        }
                    }
                } else {
                    // Create new exercise
                    WorkoutExercise newExercise = new WorkoutExercise();
                    newExercise.setWorkout(workout);
                    newExercise.setName(exRequest.getName());
                    newExercise.setOrder(exRequest.getOrder());
                    newExercise.setSkipped(exRequest.getSkipped() != null ? exRequest.getSkipped() : false);
                    updateExerciseSets(newExercise, exRequest.getSets());
                    workout.getExercises().add(newExercise);
                }
            }
        } else {
            // No exercises provided - clear all
            workout.getExercises().clear();
        }

        workoutRepository.save(workout);
        return mapToWorkoutResponse(workout);
    }

    private void updateExerciseSets(WorkoutExercise exercise, List<CreateWorkoutRequest.WorkoutExerciseRequest.WorkoutSetRequest> setRequests) {
        if (setRequests == null || setRequests.isEmpty()) {
            // No sets provided - clear all
            exercise.getSets().clear();
            return;
        }

        // Process each set in request
        for (CreateWorkoutRequest.WorkoutExerciseRequest.WorkoutSetRequest setRequest : setRequests) {
            if (setRequest.getId() != null) {
                // Update existing set
                boolean found = false;
                for (WorkoutSet existingSet : exercise.getSets()) {
                    if (existingSet.getId().equals(setRequest.getId())) {
                        existingSet.setSetNumber(setRequest.getSetNumber());
                        updateSetSegments(existingSet, setRequest.getSegments());
                        found = true;
                        break;
                    }
                }
                
                if (!found) {
                    // Set not found, create new one
                    WorkoutSet newSet = new WorkoutSet();
                    newSet.setExercise(exercise);
                    newSet.setSetNumber(setRequest.getSetNumber());
                    updateSetSegments(newSet, setRequest.getSegments());
                    exercise.getSets().add(newSet);
                }
            } else {
                // Create new set
                WorkoutSet newSet = new WorkoutSet();
                newSet.setExercise(exercise);
                newSet.setSetNumber(setRequest.getSetNumber());
                updateSetSegments(newSet, setRequest.getSegments());
                exercise.getSets().add(newSet);
            }
        }
    }

    private void updateSetSegments(WorkoutSet set, List<CreateWorkoutRequest.WorkoutExerciseRequest.WorkoutSetRequest.SetSegmentRequest> segmentRequests) {
        if (segmentRequests == null || segmentRequests.isEmpty()) {
            // No segments provided - clear all
            set.getSegments().clear();
            return;
        }

        // Process each segment in request
        for (CreateWorkoutRequest.WorkoutExerciseRequest.WorkoutSetRequest.SetSegmentRequest segRequest : segmentRequests) {
            if (segRequest.getId() != null) {
                // Update existing segment
                boolean found = false;
                for (SetSegment existingSegment : set.getSegments()) {
                    if (existingSegment.getId().equals(segRequest.getId())) {
                        existingSegment.setWeight(segRequest.getWeight());
                        existingSegment.setRepsFrom(segRequest.getRepsFrom());
                        existingSegment.setRepsTo(segRequest.getRepsTo());
                        existingSegment.setSegmentOrder(segRequest.getSegmentOrder());
                        existingSegment.setNotes(segRequest.getNotes());
                        found = true;
                        break;
                    }
                }
                
                if (!found) {
                    // Segment not found, create new one
                    SetSegment newSegment = new SetSegment();
                    newSegment.setSet(set);
                    newSegment.setWeight(segRequest.getWeight());
                    newSegment.setRepsFrom(segRequest.getRepsFrom());
                    newSegment.setRepsTo(segRequest.getRepsTo());
                    newSegment.setSegmentOrder(segRequest.getSegmentOrder());
                    newSegment.setNotes(segRequest.getNotes());
                    set.getSegments().add(newSegment);
                }
            } else {
                // Create new segment
                SetSegment newSegment = new SetSegment();
                newSegment.setSet(set);
                newSegment.setWeight(segRequest.getWeight());
                newSegment.setRepsFrom(segRequest.getRepsFrom());
                newSegment.setRepsTo(segRequest.getRepsTo());
                newSegment.setSegmentOrder(segRequest.getSegmentOrder());
                newSegment.setNotes(segRequest.getNotes());
                set.getSegments().add(newSegment);
            }
        }
    }

    public WorkoutResponse mapToWorkoutResponse(Workout workout) {
        WorkoutResponse response = new WorkoutResponse();
        response.setId(workout.getId());
        response.setUserId(workout.getUser().getId());
        response.setPlanId(workout.getPlan() != null ? workout.getPlan().getId() : null);
        response.setWorkoutDate(workout.getWorkoutDate());
        response.setStartedAt(workout.getStartedAt());
        response.setEndedAt(workout.getEndedAt());
        response.setCreatedAt(workout.getCreatedAt());
        response.setUpdatedAt(workout.getUpdatedAt());

        if (workout.getExercises() != null) {
            response.setExercises(
                    workout.getExercises().stream()
                            .map(this::mapToExerciseResponse)
                            .collect(Collectors.toList())
            );
        }

        return response;
    }

    private WorkoutResponse.WorkoutExerciseResponse mapToExerciseResponse(WorkoutExercise exercise) {
        WorkoutResponse.WorkoutExerciseResponse response = new WorkoutResponse.WorkoutExerciseResponse();
        response.setId(exercise.getId());
        response.setName(exercise.getName());
        response.setOrder(exercise.getOrder());
        response.setSkipped(exercise.getSkipped());

        if (exercise.getSets() != null) {
            response.setSets(
                    exercise.getSets().stream()
                            .map(this::mapToSetResponse)
                            .collect(Collectors.toList())
            );
        }

        return response;
    }

    private WorkoutResponse.WorkoutExerciseResponse.WorkoutSetResponse mapToSetResponse(WorkoutSet set) {
        WorkoutResponse.WorkoutExerciseResponse.WorkoutSetResponse response = new WorkoutResponse.WorkoutExerciseResponse.WorkoutSetResponse();
        response.setId(set.getId());
        response.setSetNumber(set.getSetNumber());

        if (set.getSegments() != null) {
            response.setSegments(
                    set.getSegments().stream()
                            .map(this::mapToSegmentResponse)
                            .collect(Collectors.toList())
            );
        }

        return response;
    }

    private WorkoutResponse.WorkoutExerciseResponse.WorkoutSetResponse.SetSegmentResponse mapToSegmentResponse(SetSegment segment) {
        return new WorkoutResponse.WorkoutExerciseResponse.WorkoutSetResponse.SetSegmentResponse(
                segment.getId(),
                segment.getWeight(),
                segment.getRepsFrom(),
                segment.getRepsTo(),
                segment.getSegmentOrder(),
                segment.getNotes()
        );
    }
}
