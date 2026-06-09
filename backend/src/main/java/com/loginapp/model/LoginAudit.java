package com.loginapp.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Entity
@Table(name = "login_audit")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String username;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    private boolean success;

    private String reason;

    @Column(name = "attempted_at")
    @Builder.Default
    private LocalDateTime attemptedAt = LocalDateTime.now();
}
