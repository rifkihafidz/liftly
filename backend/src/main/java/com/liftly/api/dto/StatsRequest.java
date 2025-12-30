package com.liftly.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

/**
 * Request body for stats summary endpoint
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StatsRequest {
    private Long userId;
    private LocalDate startDate;
    private LocalDate endDate;
}
