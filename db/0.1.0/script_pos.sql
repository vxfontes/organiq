ALTER DATABASE inbota SET TimeZone TO 'America/Sao_Paulo';

-- Seed base templates for home insights

WITH seed(category, title_template, summary_template, footer_template, is_focus, min_gap_minutes, priority) AS (
    VALUES
        ('END_OF_DAY', 'Dia encerrando', 'Hoje ja nao ha muito tempo livre.', 'Planeje o comeco de amanha.', false, 0, 100),
        ('PENDING_TIMES', 'Horarios pendentes', '{{untimed_count}} ainda sem horario.', 'Defina os horarios para se organizar melhor', false, 0, 90),
        ('MISSING_TIMES', 'Faltam horarios', '{{untimed_count}} compromisso(s) ainda sem horario.', 'Defina os horarios para organizar melhor.', false, 0, 80),
        ('MELHOR_MOMENTO', 'Melhor momento', '{{start}} - {{end}} para fazer algo em paz.', '{{footer_dynamic}}', true, 120, 70),
        ('GOOD_FREE_TIME', 'Bom tempo livre', '{{start}} - {{end}} esta disponivel.', 'Da para resolver algo importante.', true, 45, 60),
        ('FREE_TIME', 'Tempo livre', '{{start}} - {{end}} ({{duration}} min livres).', 'Que tal adiantar algo as {{start}}?', true, 0, 50),
        ('BUSY', 'Dia mais corrido', 'Maior tempo livre hoje e {{start}} - {{end}}.', 'Tente aproveitar pequenas pausas.', false, 0, 10)
)
INSERT INTO inbota.home_insight_templates
    (category, title_template, summary_template, footer_template, is_focus, min_gap_minutes, priority)
SELECT
    s.category,
    s.title_template,
    s.summary_template,
    s.footer_template,
    s.is_focus,
    s.min_gap_minutes,
    s.priority
FROM seed s
WHERE NOT EXISTS (
    SELECT 1
    FROM inbota.home_insight_templates t
    WHERE t.category = s.category
      AND t.priority = s.priority
      AND COALESCE(t.min_gap_minutes, -1) = COALESCE(s.min_gap_minutes, -1)
);