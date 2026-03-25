package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type rateLimitEntry struct {
	start time.Time
	count int
}

// RateLimitByIP applies a fixed-window in-memory rate limit per client IP.
func RateLimitByIP(limit int, window time.Duration) gin.HandlerFunc {
	if limit <= 0 {
		limit = 120
	}
	if window <= 0 {
		window = time.Minute
	}

	var (
		mu          sync.Mutex
		entries     = make(map[string]rateLimitEntry)
		lastCleanup = time.Now()
	)

	return func(c *gin.Context) {
		ip := c.ClientIP()
		if ip == "" {
			ip = "unknown"
		}

		now := time.Now()
		allowed := false

		mu.Lock()
		entry, ok := entries[ip]
		if !ok || now.Sub(entry.start) >= window {
			entry = rateLimitEntry{start: now, count: 1}
			entries[ip] = entry
			allowed = true
		} else if entry.count < limit {
			entry.count++
			entries[ip] = entry
			allowed = true
		}

		if now.Sub(lastCleanup) >= window {
			cutoff := now.Add(-2 * window)
			for key, value := range entries {
				if value.start.Before(cutoff) {
					delete(entries, key)
				}
			}
			lastCleanup = now
		}
		mu.Unlock()

		if !allowed {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error":     "rate_limited",
				"requestId": GetRequestID(c),
			})
			return
		}

		c.Next()
	}
}
