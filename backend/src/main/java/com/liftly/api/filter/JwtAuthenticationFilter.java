package com.liftly.api.filter;

import com.liftly.api.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        String requestPath = request.getRequestURI();
        
        // Skip authentication untuk login dan register (permit all)
        if (requestPath.contains("/auth/login") || requestPath.contains("/auth/register")) {
            filterChain.doFilter(request, response);
            return;
        }
        
        // Untuk path lain, require token
        String authHeader = request.getHeader("Authorization");
        
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            
            // Validasi JWT token
            if (jwtService.validateToken(token)) {
                try {
                    String email = jwtService.extractEmail(token);
                    
                    // Set authentication di context
                    Authentication auth = new UsernamePasswordAuthenticationToken(
                            email, null, Collections.emptyList()
                    );
                    SecurityContextHolder.getContext().setAuthentication(auth);
                    filterChain.doFilter(request, response);
                } catch (Exception e) {
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType("application/json");
                    response.getWriter().write("{\"message\": \"Invalid token\"}");
                }
            } else {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json");
                response.getWriter().write("{\"message\": \"Invalid or expired token\"}");
            }
        } else {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"message\": \"Missing authorization header\"}");
        }
    }
}
