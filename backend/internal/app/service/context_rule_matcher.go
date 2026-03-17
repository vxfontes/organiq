package service

import (
	"strings"
	"unicode"

	"organiq/backend/internal/app/domain"
)

type MatchedContext struct {
	RuleID    string
	Keyword   string
	FlagID    string
	SubflagID *string
}

type ContextRuleMatcher struct{}

func NewContextRuleMatcher() *ContextRuleMatcher {
	return &ContextRuleMatcher{}
}

func (m *ContextRuleMatcher) Match(text string, rules []domain.ContextRule) *MatchedContext {
	normalized := normalizeText(text)
	if normalized == "" {
		return nil
	}

	var best *MatchedContext
	bestScore := -1
	bestIndex := -1

	for _, rule := range rules {
		keyword := strings.TrimSpace(rule.Keyword)
		if keyword == "" {
			continue
		}
		normKeyword := normalizeText(keyword)
		if normKeyword == "" {
			continue
		}

		idx := indexOfWord(normalized, normKeyword)
		if idx < 0 {
			continue
		}

		score := len(normKeyword)
		if score > bestScore || (score == bestScore && (bestIndex == -1 || idx < bestIndex)) {
			match := MatchedContext{
				RuleID:    rule.ID,
				Keyword:   rule.Keyword,
				FlagID:    rule.FlagID,
				SubflagID: rule.SubflagID,
			}
			best = &match
			bestScore = score
			bestIndex = idx
		}
	}

	return best
}

func normalizeText(text string) string {
	lower := strings.ToLower(text)
	var b strings.Builder
	b.Grow(len(lower))
	lastSpace := false
	for _, r := range lower {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			b.WriteRune(r)
			lastSpace = false
			continue
		}
		if unicode.IsSpace(r) || r == '-' || r == '_' || r == '/' || r == '\\' {
			if !lastSpace {
				b.WriteByte(' ')
				lastSpace = true
			}
			continue
		}
		if !lastSpace {
			b.WriteByte(' ')
			lastSpace = true
		}
	}
	return strings.TrimSpace(b.String())
}

func indexOfWord(text, keyword string) int {
	if text == "" || keyword == "" {
		return -1
	}
	padded := " " + text + " "
	needle := " " + keyword + " "
	return strings.Index(padded, needle)
}
