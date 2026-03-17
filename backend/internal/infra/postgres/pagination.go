package postgres

import (
	"strconv"

	"organiq/backend/internal/app/repository"
)

const (
	defaultLimit = 50
	maxLimit     = 200
)

func limitOffset(opts repository.ListOptions) (int, int, error) {
	limit := opts.Limit
	if limit <= 0 {
		limit = defaultLimit
	}
	if limit > maxLimit {
		limit = maxLimit
	}

	offset := 0
	if opts.Cursor != "" {
		parsed, err := strconv.Atoi(opts.Cursor)
		if err != nil || parsed < 0 {
			return 0, 0, ErrInvalidCursor
		}
		offset = parsed
	}

	return limit, offset, nil
}

func nextOffsetCursor(offset, count, limit int) *string {
	if count < limit {
		return nil
	}
	next := strconv.Itoa(offset + count)
	return &next
}
