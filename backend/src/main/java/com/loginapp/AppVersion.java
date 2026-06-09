package com.loginapp;

/**
 * AppVersion - Single source of truth for application version.
 *
 * This file is intentionally simple so CI/CD pipelines can update
 * the VERSION string to trigger a new build/deployment.
 *
 * To release a new version: update VERSION below, commit, and push.
 */
public final class AppVersion {

    // ─── UPDATE THIS STRING TO TRIGGER A NEW DEPLOYMENT ─────────────────────
    public static final String VERSION = "1.0.0";
    // ─────────────────────────────────────────────────────────────────────────

    public static final String BUILD_DATE = "2026-05-06";
    public static final String CODENAME   = "Seagull";

    private AppVersion() { /* utility class – no instantiation */ }

    /** Returns a formatted version string, e.g. "v1.0.0 · Seagull · 2026-05-08" */
    public static String full() {
        return "v" + VERSION + " · " + CODENAME + " · " + BUILD_DATE;
    }
}
