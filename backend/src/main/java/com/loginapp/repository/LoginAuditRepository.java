package com.loginapp.repository;

import com.loginapp.model.LoginAudit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface LoginAuditRepository extends JpaRepository<LoginAudit, Long> {

    @Query("SELECT COUNT(a) FROM LoginAudit a " +
            "WHERE a.username = :username AND a.success = false " +
            "AND a.attemptedAt >= :since")
    long countFailedAttempts(String username, LocalDateTime since);
}
