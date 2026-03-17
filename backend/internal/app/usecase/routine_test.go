package usecase

import (
	"testing"
	"time"

	"organiq/backend/internal/app/domain"
)

func TestShouldShowRoutineForDate_RespectsStartsOnForWeekly(t *testing.T) {
	r := domain.Routine{RecurrenceType: "weekly", StartsOn: "2026-03-17"}

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

func TestComputeStartsOn_SanitizesWhenStartsOnIsNotSelectedWeekday(t *testing.T) {
	now := time.Date(2026, 3, 11, 19, 0, 0, 0, time.UTC) // Wed
	input := "2026-03-11"                                   // also Wed

	startsOn := computeStartsOn(now, []int{int(time.Tuesday)}, &input)
	if startsOn != "2026-03-17" {
		t.Fatalf("expected startsOn to sanitize to next Tuesday 2026-03-17, got %s", startsOn)
	}
}
