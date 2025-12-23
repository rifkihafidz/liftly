package com.liftly.api.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
    private boolean success;
    private int statusCode;
    private String message;
    private T data;
    private Object errors;

    // Success response
    public static <T> ApiResponse<T> success(T data, String message, int statusCode) {
        return ApiResponse.<T>builder()
                .success(true)
                .statusCode(statusCode)
                .message(message)
                .data(data)
                .build();
    }

    // Error response
    public static <T> ApiResponse<T> error(String message, int statusCode, Object errors) {
        return ApiResponse.<T>builder()
                .success(false)
                .statusCode(statusCode)
                .message(message)
                .errors(errors)
                .build();
    }

    // Error response without errors object
    public static <T> ApiResponse<T> error(String message, int statusCode) {
        return ApiResponse.<T>builder()
                .success(false)
                .statusCode(statusCode)
                .message(message)
                .build();
    }
}
