package com.liftly.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateUserRequest {
    private String firstName;
    
    private String lastName;
    
    @Email(message = "Email harus valid")
    private String email;
    
    @Size(min = 8, message = "Password minimal 8 karakter")
    private String password;
}
