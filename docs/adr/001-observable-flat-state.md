# 001: @Observable con propiedades planas (no nested State struct)

## Status: Accepted

## Decisión

Los ViewModels exponen estado como propiedades directas en lugar de un struct anidado `state: MiState`.

```swift
// Patrón adoptado:
@Observable final class EventsViewModel {
    private(set) var events: [Event] = []
    private(set) var status: Status = .idle
    var query: String = ""
}

// Patrón descartado:
@Observable final class EventsViewModel {
    private(set) var state: EventsState = .init()
}
struct EventsState { var events: [Event] = []; var status: Status = .idle }
```

## Contexto

`@Observable` (Swift Observation framework, iOS 17+) trackea cambios a nivel de *stored property* individual. Cuando una View accede a `viewModel.state.status`, el framework registra una dependencia en `state` completo, no en `state.status`. Cualquier mutación a `state` — incluyendo cambios en propiedades no usadas por esa View — invalida y re-renderiza la View.

Con propiedades planas (`viewModel.status`), el framework registra dependencia exactamente en `status`. La View solo re-renderiza cuando `status` cambia.

## Consecuencias

- **Positivo**: Re-renders mínimos y precisos. Views que solo leen `query` no re-renderizan cuando `status` cambia.
- **Positivo**: Menos boilerplate. No se necesita struct `State` separado ni sus initializers.
- **Negativo**: Estado más "disperso" visualmente en el ViewModel. Mitigado por convención: primero propiedades `private(set)`, luego propiedades de binding.
- **Negativo**: Más difícil hacer snapshot completo del estado (útil para testing). Mitigado cuando se agreguen tests: crear struct de captura ad-hoc en el test, no en producción.
