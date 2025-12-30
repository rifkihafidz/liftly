package com.liftly.api.service;

import com.liftly.api.dto.LoginRequest;
import com.liftly.api.dto.LoginResponse;
import com.liftly.api.dto.RegisterRequest;
import com.liftly.api.dto.UpdateUserRequest;
import com.liftly.api.dto.UserResponse;
import com.liftly.api.entity.User;
import com.liftly.api.exception.AuthenticationException;
import com.liftly.api.exception.UserAlreadyExistsException;
import com.liftly.api.repository.PlanRepository;
import com.liftly.api.repository.UserRepository;
import com.liftly.api.repository.WorkoutRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final PlanRepository planRepository;
    private final WorkoutRepository workoutRepository;
    private final PasswordEncoder passwordEncoder;

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AuthenticationException("Email atau password salah"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new AuthenticationException("Email atau password salah");
        }

        if (!user.getActive()) {
            throw new AuthenticationException("Akun Anda sudah dinonaktifkan");
        }

        return new LoginResponse(
                user.getId(),
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                "Login successful"
        );
    }

    public LoginResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new UserAlreadyExistsException("Email already registered");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setActive(true);

        userRepository.save(user);

        return new LoginResponse(
                user.getId(),
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                "Registration successful"
        );
    }

    public void logout(Long userId) {
        // Token invalidation dapat dilakukan di sisi client
        // atau menggunakan token blacklist di database
    }

    public UserResponse updateUser(Long userId, UpdateUserRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthenticationException("User tidak ditemukan"));

        // Check if email is already taken by another user
        if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
            if (userRepository.existsByEmail(request.getEmail())) {
                throw new UserAlreadyExistsException("Email sudah terdaftar");
            }
            user.setEmail(request.getEmail());
        }

        // Update optional fields
        if (request.getFirstName() != null && !request.getFirstName().isEmpty()) {
            user.setFirstName(request.getFirstName());
        }

        if (request.getLastName() != null && !request.getLastName().isEmpty()) {
            user.setLastName(request.getLastName());
        }

        // Update password if provided
        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(request.getPassword()));
        }

        User updatedUser = userRepository.save(user);
        return mapToUserResponse(updatedUser);
    }

    public UserResponse getUserById(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthenticationException("User tidak ditemukan"));
        return mapToUserResponse(user);
    }

    public void deleteUser(Long userId) {
        userRepository.findById(userId)
                .orElseThrow(() -> new AuthenticationException("User tidak ditemukan"));
        
        // Delete all workouts associated with user (cascade)
        workoutRepository.deleteByUserId(userId);
        
        // Delete all plans associated with user (cascade)
        planRepository.deleteByUserId(userId);
        
        // Hard delete user
        userRepository.deleteById(userId);
    }

    private UserResponse mapToUserResponse(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                user.getActive(),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }
}
