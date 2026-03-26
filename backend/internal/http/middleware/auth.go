package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const userIDKey = "user_id"

// Auth validates a Bearer JWT and stores userId (sub) in context.
func Auth(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		sub, code := parseBearerUserID(secret, c.GetHeader("Authorization"))
		if code != "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": code})
			return
		}
		c.Set(userIDKey, sub)
		c.Next()
	}
}

// OptionalAuth stores userId when a valid Bearer JWT is present and ignores missing/invalid auth.
func OptionalAuth(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		sub, _ := parseBearerUserID(secret, c.GetHeader("Authorization"))
		if sub != "" {
			c.Set(userIDKey, sub)
		}
		c.Next()
	}
}

func parseBearerUserID(secret, authHeader string) (string, string) {
	if secret == "" {
		return "", "missing_jwt_secret"
	}

	parts := strings.Fields(authHeader)
	if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
		return "", "invalid_auth_header"
	}

	tokenStr := parts[1]
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrTokenUnverifiable
		}
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return "", "invalid_token"
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", "invalid_claims"
	}
	sub, _ := claims["sub"].(string)
	if sub == "" {
		return "", "missing_sub"
	}
	return sub, ""
}

// GetUserID returns the userId from gin context.
func GetUserID(c *gin.Context) string {
	if v, ok := c.Get(userIDKey); ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}
