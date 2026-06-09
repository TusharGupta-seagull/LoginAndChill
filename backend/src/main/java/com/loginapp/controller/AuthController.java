package com.loginapp.controller;

import com.loginapp.AppVersion;
import com.loginapp.model.AuthDTO;
import com.loginapp.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /** POST /api/auth/login */
    @PostMapping("/login")
    public ResponseEntity<AuthDTO.ApiResponse> login(
            @Valid @RequestBody AuthDTO.LoginRequest request,
            HttpServletRequest httpRequest) {

        try {
            String ip = resolveIp(httpRequest);
            AuthDTO.LoginResponse loginResponse = authService.login(request, ip);
            return ResponseEntity.ok(AuthDTO.ApiResponse.ok("Login successful", loginResponse));
        } catch (AuthService.LoginException ex) {
            return ResponseEntity.status(401)
                    .body(AuthDTO.ApiResponse.fail(ex.getMessage()));
        }
    }

    /** GET /api/auth/version – returns the current app version */
    @GetMapping("/version")
    public ResponseEntity<AuthDTO.VersionResponse> version() {
        return ResponseEntity.ok(new AuthDTO.VersionResponse(
                AppVersion.VERSION,
                AppVersion.full(),
                AppVersion.BUILD_DATE,
                AppVersion.CODENAME
        ));
    }

    /** GET /api/auth/health */
    @GetMapping("/health")
    public ResponseEntity<AuthDTO.ApiResponse> health() {
        return ResponseEntity.ok(AuthDTO.ApiResponse.ok("Service is running", null));
    }

    // ── Private

    private String resolveIp(HttpServletRequest req) {
        String xff = req.getHeader("X-Forwarded-For");
        return (xff != null && !xff.isBlank())
                ? xff.split(",")[0].trim()
                : req.getRemoteAddr();
    }
}
