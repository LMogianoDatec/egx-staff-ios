# 004: ServiceLocator (sl) en lugar de @Environment para inyección de dependencias

## Status: Accepted

## Decisión

Las dependencias (ViewModels, repositorios, use cases) se resuelven mediante un ServiceLocator global (`sl`) en lugar de `@Environment` de SwiftUI.

```swift
// Patrón adoptado — resolución en init() de la View:
struct EventsView: View {
    @State private var viewModel: EventsViewModel

    init() {
        self._viewModel = State(initialValue: sl())
    }
}

// Patrón descartado:
struct EventsView: View {
    @Environment(EventsViewModel.self) private var viewModel
}
```

## Contexto

Tres patrones de DI evaluados para SwiftUI + Clean Architecture:

| Patrón | Ventajas | Desventajas |
|--------|----------|-------------|
| `@Environment` | Nativo SwiftUI, composable | Requiere pasar dependencias por toda la jerarquía de views; dificil sin acoplamiento del árbol |
| `@EnvironmentObject` | Similar a @Environment | Crash en runtime si no se provee; no type-safe en Swift 5.9+ |
| ServiceLocator (`sl`) | Resolución global, sin prop drilling, igual que GetIt en Flutter/Android | Global mutable state; más difícil de aislar en tests |

El proyecto tiene un equipo iOS + Android en paralelo. Android usa GetIt como DI. Mantener el mismo patrón conceptual reduce la carga cognitiva al cambiar de plataforma.

`@Environment` funciona bien para dependencias que fluyen naturalmente por el árbol de views (router, theme, locale). Para ViewModels con su propio ciclo de vida, el ServiceLocator evita prop drilling a través de views intermedias.

## Consecuencias

- **Positivo**: Sin prop drilling — cada View resuelve lo que necesita directamente.
- **Positivo**: Alineado con el patrón Android (GetIt) — mismo modelo mental.
- **Positivo**: Setup centralizado y explícito en `Injection.swift` + módulos.
- **Negativo**: Estado global — en tests, `sl` requiere setup explícito o reemplazo de registros.
- **Negativo**: Las dependencias de una View no son visibles en su signatura — hay que leer el `init()`.
- **Mitigación para tests**: `ServiceLocator` soporta `registerFactory` que permite sobrescribir registros en tests con mocks.
- **Convención**: `@Environment` se usa para `AppRouter` (fluye por el árbol). `sl` para ViewModels y use cases.
