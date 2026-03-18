package push

import (
	"context"
	"fmt"
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
	if credentialsFile != "" {
		opts = append(opts, option.WithCredentialsFile(credentialsFile))
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
