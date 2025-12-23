package com.liftly.api.service;

import com.liftly.api.dto.LoginRequest;
import com.liftly.api.dto.LoginResponse;
import com.liftly.api.dto.RegisterRequest;
import com.liftly.api.entity.User;
import com.liftly.api.exception.AuthenticationException;
import com.liftly.api.exception.UserAlreadyExistsException;
import com.liftly.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
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
}
