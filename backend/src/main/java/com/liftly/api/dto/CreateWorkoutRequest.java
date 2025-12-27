package com.liftly.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateWorkoutRequest {
    private LocalDateTime workoutDate;
    private LocalDateTime startedAt;
    private LocalDateTime endedAt;
    private Long planId;
    private List<WorkoutExerciseRequest> exercises;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WorkoutExerciseRequest {
        private Long id;
        private String name;
        private Integer order;
        private Boolean skipped;
        private List<WorkoutSetRequest> sets;

        @Data
        @NoArgsConstructor
        @AllArgsConstructor
        public static class WorkoutSetRequest {
            private Long id;
            private Integer setNumber;
            private List<SetSegmentRequest> segments;

            @Data
            @NoArgsConstructor
            @AllArgsConstructor
            public static class SetSegmentRequest {
                private Long id;
                private Double weight;
                private Integer repsFrom;
                private Integer repsTo;
                private Integer segmentOrder;
                private String notes;
            }
        }
    }
}
