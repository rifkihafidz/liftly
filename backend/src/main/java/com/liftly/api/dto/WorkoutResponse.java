package com.liftly.api.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
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
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime workoutDate;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime startedAt;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime endedAt;
    private List<WorkoutExerciseResponse> exercises;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
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
