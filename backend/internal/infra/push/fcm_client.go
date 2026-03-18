package push

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

type FCMClient struct {
	client *messaging.Client
}

func NewFCMClient(ctx context.Context, credentialsFile string) (*FCMClient, error) {
	opts := []option.ClientOption{}
	if strings.TrimSpace(credentialsFile) != "" {
		opt, err := buildCredentialsOption(credentialsFile)
		if err != nil {
			return nil, fmt.Errorf("resolve firebase credentials: %w", err)
		}
		opts = append(opts, opt)
	}

	app, err := firebase.NewApp(ctx, nil, opts...)
	if err != nil {
		return nil, fmt.Errorf("init firebase app: %w", err)
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("init firebase messaging: %w", err)
	}

	return &FCMClient{client: client}, nil
}

type serviceAccountCredentials struct {
	Type        string `json:"type"`
	ProjectID   string `json:"project_id"`
	ClientEmail string `json:"client_email"`
	PrivateKey  string `json:"private_key"`
}

func buildCredentialsOption(raw string) (option.ClientOption, error) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return nil, fmt.Errorf("empty credentials")
	}

	// Accepts direct service-account JSON in env var.
	if strings.HasPrefix(trimmed, "{") {
		if err := validateServiceAccountJSON([]byte(trimmed)); err != nil {
			return nil, err
		}
		return option.WithCredentialsJSON([]byte(trimmed)), nil
	}

	// Accepts base64-encoded service-account JSON in env var.
	if strings.HasPrefix(trimmed, "base64:") {
		decoded, err := base64.StdEncoding.DecodeString(strings.TrimPrefix(trimmed, "base64:"))
		if err != nil {
			return nil, fmt.Errorf("decode base64 credentials: %w", err)
		}
		if err := validateServiceAccountJSON(decoded); err != nil {
			return nil, err
		}
		return option.WithCredentialsJSON(decoded), nil
	}

	if _, err := os.Stat(trimmed); err != nil {
		return nil, fmt.Errorf("credentials file not found: %w", err)
	}

	content, err := os.ReadFile(trimmed)
	if err != nil {
		return nil, fmt.Errorf("read credentials file: %w", err)
	}
	if err := validateServiceAccountJSON(content); err != nil {
		return nil, err
	}

	return option.WithCredentialsFile(trimmed), nil
}

func validateServiceAccountJSON(raw []byte) error {
	var creds serviceAccountCredentials
	if err := json.Unmarshal(raw, &creds); err != nil {
		return fmt.Errorf("invalid credentials json: %w", err)
	}
	if strings.TrimSpace(creds.Type) != "service_account" {
		return fmt.Errorf("credentials type must be service_account")
	}
	if strings.TrimSpace(creds.ProjectID) == "" {
		return fmt.Errorf("credentials missing project_id")
	}
	if strings.TrimSpace(creds.ClientEmail) == "" {
		return fmt.Errorf("credentials missing client_email")
	}
	if strings.TrimSpace(creds.PrivateKey) == "" {
		return fmt.Errorf("credentials missing private_key")
	}
	return nil
}

func (c *FCMClient) Send(ctx context.Context, pushToken, title, body string, data map[string]string) error {
	if c == nil || c.client == nil {
		return fmt.Errorf("fcm_client_not_initialized")
	}

	msg := &messaging.Message{
		Token: pushToken,
		Data:  data,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				ChannelID: "high_importance_channel",
			},
		},
		APNS: &messaging.APNSConfig{
			Headers: map[string]string{
				"apns-priority": "10",
			},
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound: "default",
				},
			},
		},
	}

	if _, err := c.client.Send(ctx, msg); err != nil {
		return fmt.Errorf("send fcm message: %w", err)
	}

	return nil
}

func IsInvalidTokenError(err error) bool {
	if err == nil {
		return false
	}

	if messaging.IsUnregistered(err) {
		return true
	}

	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "registration token") ||
		strings.Contains(msg, "requested entity was not found")
}

func ErrorCode(err error) string {
	if err == nil {
		return ""
	}

	if messaging.IsUnregistered(err) {
		return "unregistered"
	}

	msg := strings.ToLower(err.Error())
	switch {
	case strings.Contains(msg, "registration token"), strings.Contains(msg, "invalid argument"):
		return "invalid_token"
	case strings.Contains(msg, "permission"), strings.Contains(msg, "auth"):
		return "provider_auth_error"
	default:
		return "send_error"
	}
}
