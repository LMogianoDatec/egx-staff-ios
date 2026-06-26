# EGX Staff — Claude Code Context

Control de acceso QR para eventos. iOS 17.6+, Swift 5.9+, cero dependencias externas.

## Autores

- Leonardo Mogiano (lmogiano@datec.com.bo)

## Arquitectura

**Clean Architecture** estricta con tres capas por feature. Dependencias unidireccionales:

```
Presentation → Domain ← Data
```

- **Domain**: puro Swift — Entities, Repository protocols, Use Cases, DomainErrors. Sin imports de frameworks.
- **Data**: implementaciones concretas — DTOs, mappers, DataSources, RepositoryImpl.
- **Presentation**: SwiftUI Views + `@MainActor @Observable` ViewModels.

Nunca romper las dependencias de capas. Data no importa Presentation. Domain no importa ni Data ni Presentation.

## Patrón de ViewModels (MVVM-I)

```swift
@MainActor @Observable final class MiViewModel {
    private(set) var items: [Item] = []
    private(set) var status: Status = .idle
    var query: String = ""               // binding directo

    func handle(_ intent: MiIntent) { } // única puerta desde la View
}
```

- Estado como **propiedades directas** (nunca `state: MiState`). `@Observable` trackea a nivel de stored property — un nested struct invalida todo el árbol.
- Intents como enum: `LoginIntent`, `EventsIntent`, `ScannerIntent`.
- Método de entrada: siempre `handle(_:)` (no `send`, no verbos individuales públicos).

## Estructura de un feature nuevo

```
Features/<Feature>/
├── <Feature>Module.swift          # Registra DI del feature
├── Application/
│   └── <Feature>ViewModel.swift
├── Data/
│   ├── DTOs/
│   ├── DataSources/
│   └── <Feature>RepositoryImpl.swift
├── Domain/
│   ├── Entities/
│   ├── <Feature>Repository.swift  # protocolo
│   ├── UseCases/
│   └── DomainErrors/
└── Presentation/
    ├── <Feature>View.swift
    └── Components/
```

Registrar el módulo en `Injection.swift` después de `CoreModule`.

## Inyección de dependencias

Contenedor GetIt-style. Instancia global: `sl`.

```swift
sl.registerLazySingleton(T.self) { ... }  // una sola instancia, lazy
sl.registerFactory(T.self) { ... }         // nueva instancia por acceso
sl.registerSingleton(T.self, instance: x)  // instancia ya creada
```

Resolución en Views: `self._viewModel = State(initialValue: sl())` en `init()`.

## Networking

```swift
// Crear un endpoint:
Endpoint<MiResponse>(path: "/api/v1/ruta", method: .get, requiresAuth: true, domain: "Mi")

// Llamar:
let result = try await apiClient.send(endpoint)
```

Interceptores en orden: `AuthInterceptor` → `LoggingInterceptor` → URLSession → `UnauthorizedInterceptor` → `LoggingInterceptor`.

Retry automático: 2 reintentos, backoff 0.5s → 1s → 2s (multiplicador 2x, max 4s).

## Navegación

`AppRouter` inyectado como `@Environment`. Stack tipado `[Route]`:

```swift
router.push(.sessions)
router.push(.scanner(sessionId: id, eventId: eid))
router.pop()
router.popToRoot()
```

Agregar rutas nuevas en `Route` enum en `AppRouter.swift` y en el `navigationDestination` de `AppRootView`.

## Manejo de sesión

Tres capas de detección de expiración:
1. `LoadSessionUseCase` al launch — compara `expiresAt` con `Date.now`
2. `AppViewModel.revalidateSession()` al volver al frente (`scenePhase == .active`)
3. `UnauthorizedInterceptor` en 401 — publica `Notification.egxSessionExpired`

## Comandos

```bash
# Abrir proyecto
open "EGX Staff.xcodeproj"

# Sin dependencias externas — no pod install, no swift package resolve

# Activar mock data (sin red):
# En EGXStaffApp.swift: Injection.setup(apiConfiguration: .mock)
```

## Convenciones

- Nombres de entidades de dominio en inglés (`AuthSession`, `Attendee`, `AccessOutcome`)
- ViewModels y Views en inglés
- Comentarios y strings de usuario en español
- `Status` enum en cada ViewModel: `.idle`, `.loading`, `.loaded`, `.failure(message)`
- Errores de dominio como `enum DomainError: Error` por feature
- Mock data: activar con `APIConfiguration.mock` en `Injection.setup()`

## Deuda técnica activa

| Ítem | Prioridad |
|------|-----------|
| Token refresh (actualmente dura ~1 semana) | Media |
| Android en AndroidStudioProjects/EGXStaff | Alta |
| Tests de UI | Baja |
| Internacionalización | Baja |

## Deuda técnica resuelta

| Ítem | Commit |
|------|--------|
| Tests unitarios (UseCases, ViewModels) | Cubiertos: Auth, Events, Scanner, App |
| Release xcconfig → URL de producción | `ac45bfd` |
