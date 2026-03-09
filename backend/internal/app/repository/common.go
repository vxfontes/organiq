package repository

import "time"

type ListOptions struct {
	Limit   int
	Cursor  string
	StartAt *time.Time
	EndAt   *time.Time
}
