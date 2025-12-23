package com.liftly.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.NotBlank;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreatePlanRequest {
    @NotBlank(message = "Name cannot be blank")
    private String name;
    private String description;
    private List<String> exercises;
}
