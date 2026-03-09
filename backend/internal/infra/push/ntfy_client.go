package push

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
)

type NtfyClient struct {
	BaseURL string
}

func NewNtfyClient(baseURL string) *NtfyClient {
	if baseURL == "" {
		baseURL = "https://ntfy.sh"
	}
	return &NtfyClient{BaseURL: baseURL}
}

func (c *NtfyClient) Send(ctx context.Context, topic, title, body string, data map[string]string) error {
	url := fmt.Sprintf("%s/%s", c.BaseURL, topic)
	
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, strings.NewReader(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	if title != "" {
		req.Header.Set("Title", title)
	}
	
	// Add priority
	req.Header.Set("Priority", "high")

	// Add tags/icons if needed
	if nType, ok := data["type"]; ok {
		req.Header.Set("Tags", nType)
	}

	// Click URL for deep linking if available
	if clickURL, ok := data["click_url"]; ok {
		req.Header.Set("Click", clickURL)
	}

	// We can also send custom data as headers (X-Metadata-...) if needed,
	// but ntfy has some limitations on header sizes.
	// For simple deep linking, "Click" or custom tags are usually enough.

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send ntfy notification: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
		return fmt.Errorf("ntfy error status=%d body=%s", resp.StatusCode, string(respBody))
	}

	return nil
}
