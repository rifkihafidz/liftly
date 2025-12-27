package com.liftly.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutResponse {
    private Long id;
    private Long userId;
    private Long planId;
    private LocalDateTime workoutDate;
    private LocalDateTime startedAt;
    private LocalDateTime endedAt;
    private List<WorkoutExerciseResponse> exercises;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WorkoutExerciseResponse {
        private Long id;
        private String name;
        private Integer order;
        private Boolean skipped;
        private List<WorkoutSetResponse> sets;

        @Data
        @NoArgsConstructor
        @AllArgsConstructor
        public static class WorkoutSetResponse {
            private Long id;
            private Integer setNumber;
            private List<SetSegmentResponse> segments;

            @Data
            @NoArgsConstructor
            @AllArgsConstructor
            public static class SetSegmentResponse {
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
