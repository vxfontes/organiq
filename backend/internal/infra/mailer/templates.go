package mailer

import (
	"embed"
	"fmt"
	htmltemplate "html/template"
	texttemplate "text/template"
)

//go:embed templates/*.html templates/*.txt
var templatesFS embed.FS

func ParseDailyDigestTemplates() (*htmltemplate.Template, *texttemplate.Template, error) {
	htmlTmpl, err := htmltemplate.ParseFS(templatesFS, "templates/daily_digest.html")
	if err != nil {
		return nil, nil, fmt.Errorf("parse html template: %w", err)
	}

	textTmpl, err := texttemplate.ParseFS(templatesFS, "templates/daily_digest.txt")
	if err != nil {
		return nil, nil, fmt.Errorf("parse text template: %w", err)
	}

	return htmlTmpl, textTmpl, nil
}
