package repository

import "context"

type AppConfigRepository interface {
	GetAll(ctx context.Context) (map[string]string, error)
}
