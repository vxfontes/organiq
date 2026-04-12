package postgres

import "errors"

var ErrNotFound = errors.New("not_found")
var ErrInvalidCursor = errors.New("invalid_cursor")
var ErrEmailAlreadyExists = errors.New("email_already_exists")
