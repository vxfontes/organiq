package mailer

import "context"

type SendRequest struct {
	To      []string
	Subject string
	Html    string
	Text    string
}

type Mailer interface {
	Send(ctx context.Context, req SendRequest) (messageID string, err error)
}
