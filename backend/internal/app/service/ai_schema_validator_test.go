package service

import "testing"

func TestAiSchemaValidatorValidateManyArrayRoot(t *testing.T) {
	v := NewAiSchemaValidator()

	raw := []byte(`[
		{"type":"task","title":"Tirar o lixo","needs_review":false,"payload":{"dueAt":null}},
		{"type":"shopping","title":"Lista de compras","needs_review":false,"payload":{"items":[{"title":"pao","quantity":null}]}}
	]`)

	outs, err := v.ValidateMany(raw)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(outs) != 2 {
		t.Fatalf("expected 2 outputs, got %d", len(outs))
	}
	if outs[0].Output.Type != "task" {
		t.Fatalf("expected first output type task, got %s", outs[0].Output.Type)
	}
	if outs[1].Output.Type != "shopping" {
		t.Fatalf("expected second output type shopping, got %s", outs[1].Output.Type)
	}
}

func TestAiSchemaValidatorValidateManyArrayInsideMarkdown(t *testing.T) {
	v := NewAiSchemaValidator()

	raw := []byte("Segue:\n```json\n[\n" +
		"{\"type\":\"task\",\"title\":\"Item A\",\"needs_review\":false,\"payload\":{\"dueAt\":null}},\n" +
		"{\"type\":\"task\",\"title\":\"Item B\",\"needs_review\":false,\"payload\":{\"dueAt\":null}}\n" +
		"]\n```\n")

	outs, err := v.ValidateMany(raw)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(outs) != 2 {
		t.Fatalf("expected 2 outputs, got %d", len(outs))
	}
	if outs[0].Output.Title != "Item A" || outs[1].Output.Title != "Item B" {
		t.Fatalf("unexpected titles: %#v", []string{outs[0].Output.Title, outs[1].Output.Title})
	}
}
