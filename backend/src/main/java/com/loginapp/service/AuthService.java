package com.loginapp.service;

import com.loginapp.model.AuthDTO;
import com.loginapp.model.LoginAudit;
import com.loginapp.model.User;
import com.loginapp.repository.LoginAuditRepository;
import com.loginapp.repository.UserRepository;
import com.loginapp.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final LoginAuditRepository auditRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Value("${app.login.max-attempts:5}")
    private int maxAttempts;

    @Value("${app.login.lockout-minutes:15}")
    private int lockoutMinutes;

    @Value("${app.jwt.expiration-ms:3600000}")
    private long jwtExpirationMs;

    /**
     * Authenticate a user by EMAIL + PASSWORD and return a JWT on success.
     */
    @Transactional
    public AuthDTO.LoginResponse login(AuthDTO.LoginRequest request,
            String ipAddress) {

        String email = request.getEmail().trim().toLowerCase();

        // 1. Check for brute-force lockout
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(lockoutMinutes);
        long recentFails = auditRepository.countFailedAttempts(email, cutoff);
        if (recentFails >= maxAttempts) {
            audit(email, ipAddress, false, "Account temporarily locked");
            throw new LoginException("Too many failed attempts. Try again in " +
                    lockoutMinutes + " minutes.");
        }

        // 2. Load user by email
        User user = userRepository.findByEmail(email).orElse(null);

        if (user == null) {
            audit(email, ipAddress, false, "Email not found");
            throw new LoginException("Invalid email or password.");
        }

        // 3. Check account is enabled
        if (!user.isEnabled()) {
            audit(email, ipAddress, false, "Account disabled");
            throw new LoginException("Account is disabled. Contact support.");
        }

        // 4. Verify password
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            audit(email, ipAddress, false, "Bad password");
            throw new LoginException("Invalid email or password.");
        }

        // 5. Success — update last login and return JWT
        userRepository.updateLastLogin(user.getId(), LocalDateTime.now());
        audit(email, ipAddress, true, "Login successful");

        String token = jwtUtil.generateToken(user.getUsername(),
                user.getRole().name());

        log.info("Successful login: {} from {}", email, ipAddress);

        return new AuthDTO.LoginResponse(
                token,
                user.getUsername(),
                user.getEmail(),
                user.getFullName(),
                user.getRole().name(),
                jwtExpirationMs / 1000);
    }

    private void audit(String email, String ip, boolean success, String reason) {
        auditRepository.save(LoginAudit.builder()
                .username(email)
                .ipAddress(ip)
                .success(success)
                .reason(reason)
                .attemptedAt(LocalDateTime.now())
                .build());
    }

    public static class LoginException extends RuntimeException {
        public LoginException(String message) {
            super(message);
        }
    }
}
