# 003: [Route] tipado en lugar de NavigationPath

## Status: Accepted

## Decisión

`AppRouter` usa `var path: [Route]` con un enum tipado en lugar de `NavigationPath` de SwiftUI.

```swift
// Patrón adoptado:
@Observable final class AppRouter {
    var path: [Route] = []
}

enum Route: Hashable {
    case sessions
    case scanner(sessionId: String, eventId: String)
}

// Patrón descartado:
@Observable final class AppRouter {
    var path: NavigationPath = .init()
}
```

## Contexto

`NavigationPath` es type-erased: almacena rutas como `AnyHashable`. Esto implica:

1. **Sin validación en compilación** — se puede pushear cualquier tipo Hashable; un typo en el tipo no da error en compile time.
2. **No inspectable** — no se puede leer qué hay en el stack (solo `count`). Dificulta testing de navegación.
3. **Serialización opaca** — requiere `NavigationPath.CodableRepresentation` para persistir; no es trivial leer el contenido.

Con `[Route]` tipado:
- El compilador valida que solo existan rutas declaradas en `Route`.
- El stack es un array normal — se puede leer, manipular, y hacer assert en tests.
- Agregar una ruta con parámetros faltantes da error de compilación.

## Consecuencias

- **Positivo**: Seguridad de tipos en tiempo de compilación.
- **Positivo**: Stack inspeccionable → testeable sin mocks complejos.
- **Positivo**: Fácil de deep-link: se puede construir un stack `[.sessions, .scanner(…)]` y asignarlo directamente.
- **Negativo**: Requiere declarar cada ruta en el enum `Route`. Con `NavigationPath`, cualquier tipo `Hashable` + `Codable` navega automáticamente.
- **Negativo**: Al agregar un feature con nueva vista, hay que agregar el `case` en `Route` y el `navigationDestination` en `AppRootView`. Con `NavigationPath` esto es opcional.
- **Límite**: Si el proyecto crece a 20+ rutas con navegación muy dinámica, evaluar `NavigationPath` con wrappers tipados.
