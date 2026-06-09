package com.loginapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class LoginAppApplication {

    public static void main(String[] args) {
        System.out.println("═══════════════════════════════════════════");
        System.out.println("  LoginApp Backend  " + AppVersion.full());
        System.out.println("═══════════════════════════════════════════");
        SpringApplication.run(LoginAppApplication.class, args);
    }
}
