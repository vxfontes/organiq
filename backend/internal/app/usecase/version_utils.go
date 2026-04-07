package usecase

import (
	"strconv"
	"strings"
)

// CompareVersions compara v1 e v2.
// Retorna 1 se v1 > v2, -1 se v1 < v2, 0 se v1 == v2.
func CompareVersions(v1, v2 string) int {
	v1Parts := strings.Split(strings.Split(v1, "+")[0], ".")
	v2Parts := strings.Split(strings.Split(v2, "+")[0], ".")

	maxLen := len(v1Parts)
	if len(v2Parts) > maxLen {
		maxLen = len(v2Parts)
	}

	for i := 0; i < maxLen; i++ {
		var p1, p2 int
		if i < len(v1Parts) {
			p1, _ = strconv.Atoi(v1Parts[i])
		}
		if i < len(v2Parts) {
			p2, _ = strconv.Atoi(v2Parts[i])
		}

		if p1 > p2 {
			return 1
		}
		if p1 < p2 {
			return -1
		}
	}

	return 0
}
