package com.liftly.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlanResponse {
    private Long id;
    private Long userId;
    private String name;
    private String description;
    private List<PlanExerciseResponse> exercises;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PlanExerciseResponse {
        private Long id;
        private String name;
        private Integer order;
    }
}
