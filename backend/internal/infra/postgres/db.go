package postgres

import (
	"context"
	"database/sql"
	"net/url"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

type DB struct {
	*sql.DB
}

type dbtx interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
	QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
}

// NewDB opens a Postgres connection pool.
func NewDB(ctx context.Context, dsn string) (*DB, error) {
	normalizedDSN := normalizeDSN(dsn)
	db, err := sql.Open("postgres", normalizedDSN)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(30 * time.Minute)

	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		_ = db.Close()
		return nil, err
	}

	return &DB{DB: db}, nil
}

func normalizeDSN(dsn string) string {
	parsed, err := url.Parse(dsn)
	if err != nil || parsed.Scheme == "" || parsed.Host == "" {
		return dsn
	}

	query := parsed.Query()

	// Force session timezone to Brazil default.
	// Postgres stores timestamptz internally in UTC, but CURRENT_DATE/now() and casts
	// depend on the session TimeZone. Setting it here prevents "day flipped" bugs.
	opts := query.Get("options")
	tzOption := "-c TimeZone=America/Sao_Paulo"
	switch {
	case opts == "":
		query.Set("options", tzOption)
	case !strings.Contains(opts, "TimeZone=America/Sao_Paulo"):
		query.Set("options", opts+" "+tzOption)
	}

	host := parsed.Hostname()
	if strings.HasSuffix(host, ".supabase.co") || strings.HasSuffix(host, ".supabase.net") || strings.HasSuffix(host, ".supabase.com") {
		if query.Get("sslmode") == "" {
			query.Set("sslmode", "require")
		}
	}

	parsed.RawQuery = query.Encode()
	return parsed.String()
}

// Check pings the database.
func (db *DB) Check(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 1*time.Second)
	defer cancel()
	return db.PingContext(ctx)
}
