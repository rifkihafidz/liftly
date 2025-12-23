package com.liftly.api.controller;

import com.liftly.api.dto.LoginRequest;
import com.liftly.api.dto.LoginResponse;
import com.liftly.api.dto.RegisterRequest;
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
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<LoginResponse> register(@Valid @RequestBody RegisterRequest request) {
        LoginResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(
            @RequestParam Long userId,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        authService.logout(userId);
        return ResponseEntity.ok("Logout successful");
    }
}
