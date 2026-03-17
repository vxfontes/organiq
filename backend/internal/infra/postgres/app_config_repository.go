package postgres

import "context"

type AppConfigRepository struct {
	db *DB
}

func NewAppConfigRepository(db *DB) *AppConfigRepository {
	return &AppConfigRepository{db: db}
}

func (r *AppConfigRepository) GetAll(ctx context.Context) (map[string]string, error) {
	rows, err := r.db.QueryContext(ctx, `SELECT key, value FROM organiq.app_config`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	cfg := make(map[string]string)
	for rows.Next() {
		var key, value string
		if err := rows.Scan(&key, &value); err != nil {
			return nil, err
		}
		cfg[key] = value
	}
	return cfg, rows.Err()
}
