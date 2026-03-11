package usecase

import (
	"testing"
	"time"

	"inbota/backend/internal/app/domain"
)

func TestShouldShowRoutineForDate_RespectsStartsOnForWeekly(t *testing.T) {
	r := domain.Routine{RecurrenceType: "weekly", StartsOn: "2026-03-17"}

	// A date before StartsOn must not show.
	before := time.Date(2026, 3, 10, 12, 0, 0, 0, time.UTC)
	if shouldShowRoutineForDate(r, before) {
		t.Fatalf("expected weekly routine to be hidden before StartsOn")
	}

	onStart := time.Date(2026, 3, 17, 12, 0, 0, 0, time.UTC)
	if !shouldShowRoutineForDate(r, onStart) {
		t.Fatalf("expected weekly routine to show on/after StartsOn")
	}
}

func TestShouldShowRoutineForDate_BiweeklyAnchorsToStartsOnWeek(t *testing.T) {
	r := domain.Routine{RecurrenceType: "biweekly", StartsOn: "2026-03-17"}

	start := time.Date(2026, 3, 17, 12, 0, 0, 0, time.UTC)
	if !shouldShowRoutineForDate(r, start) {
		t.Fatalf("expected biweekly routine to show on StartsOn")
	}

	oneWeekLater := time.Date(2026, 3, 24, 12, 0, 0, 0, time.UTC)
	if shouldShowRoutineForDate(r, oneWeekLater) {
		t.Fatalf("expected biweekly routine to be hidden on the off-week")
	}

	twoWeeksLater := time.Date(2026, 3, 31, 12, 0, 0, 0, time.UTC)
	if !shouldShowRoutineForDate(r, twoWeeksLater) {
		t.Fatalf("expected biweekly routine to show again after 2 weeks")
	}
}

func TestNextOccurrenceDate_PicksNextWeekday(t *testing.T) {
	from := time.Date(2026, 3, 11, 19, 0, 0, 0, time.UTC) // Wed
	next := nextOccurrenceDate(from, []int{int(time.Tuesday)})

	if next.Format("2006-01-02") != "2026-03-17" {
		t.Fatalf("expected next Tuesday to be 2026-03-17, got %s", next.Format("2006-01-02"))
	}
}
