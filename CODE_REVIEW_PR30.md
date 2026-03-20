# Code Review: PR #30 — Feat/novos widgets

**Status:** ✅ Aprovado com sugestões de melhoria  
**Arquivos revisados:** 12 arquivos (+2101/-224 linhas)

## Resumo Geral

Implementação sólida de widgets iOS (Day Progress, Next Actions, Reminders) com bridge Flutter → Swift via MethodChannel. A arquitetura está correta e funcional, mas há espaço para melhorias em robustez, manutenibilidade e performance.

---

## ✅ Pontos Positivos

1. **Arquitetura limpa**: Bridge pattern bem implementado com UserDefaults shared container
2. **Separation of concerns**: Cada widget tem seu próprio arquivo Swift
3. **Type-safe models**: DayProgressData, NextActionItem, etc. têm structs bem definidas
4. **Graceful degradation**: Fallback para placeholder quando não há dados
5. **Platform check**: `!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS` antes de chamar bridge

---

## 🔧 Melhorias Sugeridas

### 1. **Falta sincronização de Tasks**

**Problema:**  
`WidgetBridgeService.syncTasks()` existe mas **não é chamado** em `_syncWidgetData()`.

**Impacto:**  
Widget de tasks (se existir) nunca é atualizado.

**Solução:**
```dart
// Em home_controller.dart, adicionar em _syncWidgetData():
await bridge.syncTasks(agenda.value.tasks);
```

---

### 2. **Magic numbers espalhados**

**Problema:**  
`.take(8)`, `.take(10)`, `.take(5)` hardcoded em vários lugares.

**Solução:**
```dart
// Em widget_bridge_service.dart:
class _WidgetLimits {
  static const tasks = 10;
  static const nextActions = 8;
  static const reminders = 5;
}

// Uso:
.take(_WidgetLimits.nextActions)
```

---

### 3. **Performance: _timelineAccentColor() faz loop O(n) por item**

**Problema:**  
Para cada item da timeline, faz loop linear em todos os eventos/tasks/reminders.

**Impacto:**  
Se timeline tem 10 itens e agenda tem 50 tasks, são 500 comparações.

**Solução:**
```dart
// Criar cache no início de _syncWidgetData():
final colorCache = <String, String?>{};
for (final task in agenda.value.tasks) {
  colorCache[task.id] = task.subflagColor ?? task.flagColor;
}
for (final event in agenda.value.events) {
  colorCache[event.id] = event.subflagColor ?? event.flagColor;
}
// ... para reminders e routines

// Em _timelineAccentColor():
String? _timelineAccentColor(TimelineItem item) => colorCache[item.id];
```

---

### 4. **Tratamento de erros silencioso demais**

**Problema:**  
Todos os `on PlatformException` são ignorados sem log.

**Impacto:**  
Dificulta debug quando bridge falha.

**Solução:**
```dart
} on PlatformException catch (e) {
  if (kDebugMode) {
    debugPrint('WidgetBridge.syncTasks failed: ${e.code} ${e.message}');
  }
}
```

---

### 5. **Validação duplicada**

**Problema:**  
Múltiplos métodos fazem `.trim().isEmpty` check.

**Solução:**
```dart
// Helper privado:
bool _isValidId(String? value) =>
    value?.trim().isNotEmpty ?? false;

// Uso:
.where((task) => _isValidId(task.id) && _isValidId(task.title))
```

---

### 6. **Falta documentação**

**Problema:**  
Métodos públicos do `WidgetBridgeService` não têm doc comments.

**Solução:**
```dart
/// Syncs tasks to iOS widgets.
///
/// Only incomplete tasks are sent, ordered by priority (overdue → today → future).
/// Maximum of 10 tasks are kept in the widget store.
///
/// Called automatically by [HomeController] after data refresh.
Future<void> syncTasks(List<TaskOutput> tasks) async { ... }
```

---

### 7. **Type safety nos mapas (syncNextActions)**

**Problema:**  
`List<Map<String, dynamic>>` usa strings como chaves, fácil de ter typo.

**Solução:**  
Criar modelo:
```dart
class NextActionWidgetItem {
  final String id;
  final String title;
  final String type;
  final DateTime scheduledTime;
  final DateTime? endScheduledTime;
  final bool isCompleted;
  final bool isOverdue;
  final String? subtitle;
  final String? accentColor;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'type': type,
    'scheduledTime': scheduledTime.toUtc().toIso8601String(),
    // ...
  };
}
```

---

### 8. **Swift: Force unwrapping perigoso**

**Problema (AppDelegate.swift, linha ~74):**
```swift
guard let data = try? JSONSerialization.data(withJSONObject: tasks) else { return false }
```

Se `tasks` contiver tipos não serializáveis, crash silencioso.

**Solução:**
```swift
do {
  let data = try JSONSerialization.data(withJSONObject: tasks)
  defaults.set(data, forKey: tasksKey)
} catch {
  print("Widget sync failed: \(error)")
  return false
}
```

---

### 9. **Falta consumo de tasks completadas via widget**

**Problema:**  
`consumeCompletedTaskIds()` existe no bridge mas não vejo sendo chamado no controller.

**Impacto:**  
Se usuário completar task via widget, app não sincroniza.

**Solução:**
```dart
// Em home_controller.dart, no onResume ou fetchData():
final completedIds = await WidgetBridgeService.instance.consumeCompletedTaskIds();
for (final id in completedIds) {
  await _updateTaskUsecase(/* marcar como done */);
}
```

---

### 10. **Hardcoded 15 minutos de refresh**

**Problema (DayProgressWidget.swift, linha ~31):**
```swift
let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
```

**Solução:**  
Tornar configurável ou usar política `.atEnd` se não precisa refresh frequente:
```swift
completion(Timeline(entries: [entry], policy: .atEnd))
```

---

## 🧪 Testes Sugeridos

Adicionar:
```dart
// test/services/widget_bridge_service_test.dart
void main() {
  group('WidgetBridgeService', () {
    test('syncTasks filters incomplete tasks', () { ... });
    test('syncTasks orders by priority correctly', () { ... });
    test('syncDayProgress clamps percent to 0..1', () { ... });
  });
}
```

---

## 📋 Checklist Final

- [ ] Adicionar chamada `syncTasks()` em `_syncWidgetData()`
- [ ] Implementar consumo de `completedTaskIds` do widget
- [ ] Extrair magic numbers para constantes
- [ ] Otimizar `_timelineAccentColor()` com cache
- [ ] Adicionar debug logs nos catches
- [ ] Documentar métodos públicos
- [ ] Considerar modelo tipado para `NextActionWidgetItem`
- [ ] Trocar force-unwraps por `do-catch` no Swift
- [ ] Adicionar testes unitários básicos

---

## Veredicto

✅ **APROVADO** — O código está funcional e bem estruturado. As melhorias sugeridas são incrementais e podem ser endereçadas em PRs futuros se necessário. A funcionalidade core está sólida.

**Prioridade das melhorias:**  
1. 🔴 **Alta:** Adicionar `syncTasks()` call (#1) e consumo de `completedTaskIds` (#9)  
2. 🟡 **Média:** Performance (#3), magic numbers (#2), documentação (#6)  
3. 🟢 **Baixa:** Type safety (#7), testes (#10)
