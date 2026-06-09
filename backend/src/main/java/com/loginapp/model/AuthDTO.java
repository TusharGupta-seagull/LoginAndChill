package com.loginapp.model;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/** DTO namespace – inner classes keep things tidy. */
public final class AuthDTO {

    private AuthDTO() {}

    // ── Login Request ─────────────────────────────────────────
    @Data
    public static class LoginRequest {
        @NotBlank(message = "Email is required")
        @Email(message = "Must be a valid email address")
        private String email;

        @NotBlank(message = "Password is required")
        @Size(min = 6, max = 128)
        private String password;
    }

    // ── Login Response ────────────────────────────────────────
    @Data
    public static class LoginResponse {
        private final String token;
        private final String username;
        private final String email;
        private final String fullName;
        private final String role;
        private final long   expiresIn;   // seconds
    }

    // ── Generic API Response ──────────────────────────────────
    @Data
    public static class ApiResponse {
        private final boolean success;
        private final String  message;
        private final Object  data;

        public static ApiResponse ok(String message, Object data) {
            return new ApiResponse(true, message, data);
        }

        public static ApiResponse fail(String message) {
            return new ApiResponse(false, message, null);
        }
    }

    // ── Version Response ──────────────────────────────────────
    @Data
    public static class VersionResponse {
        private final String version;
        private final String full;
        private final String buildDate;
        private final String codename;
    }
}
