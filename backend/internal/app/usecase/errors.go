package usecase

import "errors"

var (
	ErrMissingRequiredFields = errors.New("missing_required_fields")
	ErrInvalidStatus         = errors.New("invalid_status")
	ErrInvalidType           = errors.New("invalid_type")
	ErrInvalidSource         = errors.New("invalid_source")
	ErrInvalidPayload        = errors.New("invalid_payload")
	ErrInvalidTimeRange      = errors.New("invalid_time_range")
	ErrDependencyMissing     = errors.New("dependency_missing")
	ErrInvalidEmail          = errors.New("invalid_email")
	ErrInvalidPassword       = errors.New("invalid_password")
	ErrInvalidDisplayName    = errors.New("invalid_display_name")
	ErrRoutineOverlap        = errors.New("routine_overlap")
)
