package com.liftly.api.controller;

import com.liftly.api.dto.ApiResponse;
import com.liftly.api.dto.LoginRequest;
import com.liftly.api.dto.LoginResponse;
import com.liftly.api.dto.RegisterRequest;
import com.liftly.api.dto.UpdateUserRequest;
import com.liftly.api.dto.UserResponse;
import com.liftly.api.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AuthController {
    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Login successful", HttpStatus.OK.value()));
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<LoginResponse>> register(@Valid @RequestBody RegisterRequest request) {
        LoginResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Registration successful", HttpStatus.CREATED.value()));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<?>> logout(
            @RequestParam Long userId,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        authService.logout(userId);
        return ResponseEntity.ok(ApiResponse.success(null, "Logout successful", HttpStatus.OK.value()));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(@PathVariable Long userId) {
        UserResponse response = authService.getUserById(userId);
        return ResponseEntity.ok(ApiResponse.success(response, "User retrieved successfully", HttpStatus.OK.value()));
    }

    @PutMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(
            @PathVariable Long userId,
            @Valid @RequestBody UpdateUserRequest request) {
        UserResponse response = authService.updateUser(userId, request);
        return ResponseEntity.ok(ApiResponse.success(response, "User updated successfully", HttpStatus.OK.value()));
    }

    @DeleteMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<?>> deleteUser(@PathVariable Long userId) {
        authService.deleteUser(userId);
        return ResponseEntity.ok(ApiResponse.success(null, "User deleted successfully", HttpStatus.OK.value()));
    }
}
