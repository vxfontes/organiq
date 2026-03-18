package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config holds application configuration loaded from environment variables.
type Config struct {
	Env                          string
	Port                         int
	RequestIDHeader              string
	CORSAllowedOrigins           []string
	CORSAllowedMethods           []string
	CORSAllowedHeaders           []string
	CORSExposeHeaders            []string
	CORSAllowCredentials         bool
	LogLevel                     string
	DatabaseURL                  string
	GoogleApplicationCredentials string
	JWTSecret                    string
	AIProvider                   string
	AIAPIKey                     string
	AIBaseURL                    string
	AIModel                      string
	AIFallbackModel              string
	AIFallbackOnNeedsReview      bool
	AITimeout                    time.Duration
	AIMaxRetries                 int

	ResendAPIKey      string
	ResendFrom        string
	DigestJobInterval time.Duration

	ReadTimeout  time.Duration
	WriteTimeout time.Duration
	IdleTimeout  time.Duration
}

// Load reads environment variables and applies defaults.
func Load() (Config, error) {
	cfg := Config{
		Env:                          getEnv("APP_ENV", "dev"),
		Port:                         getEnvInt("PORT", 8080),
		RequestIDHeader:              getEnv("REQUEST_ID_HEADER", "X-Request-Id"),
		CORSAllowedOrigins:           getEnvCSV("CORS_ALLOWED_ORIGINS", []string{"http://localhost:3000", "http://127.0.0.1:3000"}),
		CORSAllowedMethods:           getEnvCSV("CORS_ALLOWED_METHODS", []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}),
		CORSAllowedHeaders:           getEnvCSV("CORS_ALLOWED_HEADERS", []string{"Authorization", "Content-Type", "X-Request-Id"}),
		CORSExposeHeaders:            getEnvCSV("CORS_EXPOSE_HEADERS", []string{"X-Request-Id"}),
		CORSAllowCredentials:         getEnvBool("CORS_ALLOW_CREDENTIALS", false),
		LogLevel:                     strings.ToLower(getEnv("LOG_LEVEL", "info")),
		DatabaseURL:                  getEnv("DATABASE_URL", ""),
		GoogleApplicationCredentials: getEnv("GOOGLE_APPLICATION_CREDENTIALS", ""),
		JWTSecret:                    getEnv("JWT_SECRET", ""),
		AIProvider:                   getEnv("AI_PROVIDER", ""),
		AIAPIKey:                     getEnv("AI_API_KEY", ""),
		AIBaseURL:                    getEnv("AI_BASE_URL", ""),
		AIModel:                      getEnv("AI_MODEL", ""),
		AIFallbackModel:              getEnv("AI_FALLBACK_MODEL", ""),
		AIFallbackOnNeedsReview:      getEnvBool("AI_FALLBACK_ON_NEEDS_REVIEW", false),
		AITimeout:                    getEnvDuration("AI_TIMEOUT", 15*time.Second),
		AIMaxRetries:                 getEnvInt("AI_MAX_RETRIES", 2),

		ResendAPIKey:      getEnv("RESEND_API_KEY", ""),
		ResendFrom:        getEnv("RESEND_FROM", "Organiq <noreply@resend.dev>"),
		DigestJobInterval: getEnvDuration("DIGEST_JOB_INTERVAL", 30*time.Minute),

		ReadTimeout:  getEnvDuration("READ_TIMEOUT", 5*time.Second),
		WriteTimeout: getEnvDuration("WRITE_TIMEOUT", 10*time.Second),
		IdleTimeout:  getEnvDuration("IDLE_TIMEOUT", 60*time.Second),
	}

	if cfg.Port <= 0 {
		return Config{}, errors.New("PORT must be > 0")
	}
	if cfg.DigestJobInterval <= 0 {
		return Config{}, errors.New("DIGEST_JOB_INTERVAL must be > 0")
	}

	return cfg, nil
}

func getEnv(key, def string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return def
}

func getEnvInt(key string, def int) int {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	parsed, err := strconv.Atoi(v)
	if err != nil {
		return def
	}
	return parsed
}

func getEnvDuration(key string, def time.Duration) time.Duration {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		return def
	}
	return d
}

func getEnvBool(key string, def bool) bool {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	parsed, err := strconv.ParseBool(v)
	if err != nil {
		return def
	}
	return parsed
}

func getEnvCSV(key string, def []string) []string {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return append([]string(nil), def...)
	}

	parts := strings.Split(v, ",")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed == "" {
			continue
		}
		out = append(out, trimmed)
	}
	if len(out) == 0 {
		return append([]string(nil), def...)
	}
	return out
}

// Addr returns server address based on Port.
func (c Config) Addr() string {
	return fmt.Sprintf(":%d", c.Port)
}
