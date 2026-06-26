# Cómo agregar un feature

Todos los features siguen el mismo patrón. Ejemplo: agregar feature `Tickets`.

---

## 1. Estructura de carpetas

```
Features/Tickets/
├── TicketsModule.swift
├── Application/
│   └── TicketsViewModel.swift
├── Data/
│   ├── DTOs/TicketDTO.swift
│   ├── DataSources/TicketsRemoteDataSource.swift
│   └── TicketsRepositoryImpl.swift
├── Domain/
│   ├── Entities/Ticket.swift
│   ├── TicketsRepository.swift          # protocolo
│   └── UseCases/FetchTicketsUseCase.swift
└── Presentation/
    ├── TicketsView.swift
    └── Components/
```

---

## 2. Orden de implementación (Domain primero)

1. **Domain** — `Ticket` entity, `TicketsRepository` protocol, `FetchTicketsUseCase`
2. **Data** — `TicketDTO` (Decodable, snake_case), mapper en `TicketsRepositoryImpl`, `TicketsRemoteDataSource`
3. **Application** — `TicketsViewModel` con propiedades planas y `handle(_ intent: TicketsIntent)`
4. **Presentation** — `TicketsView` consume el ViewModel, emite Intents
5. **Module** — `TicketsModule.register()` registra todo el grafo en `sl`

---

## 3. Registrar el módulo

En `Core/DI/Injection.swift`, después de los módulos existentes:

```swift
TicketsModule.register()
```

---

## 4. Agregar ruta (si el feature tiene navegación propia)

En `Core/Navigation/AppRouter.swift`:

```swift
enum Route: Hashable {
    case sessions
    case scanner(sessionId: String, eventId: String)
    case tickets(eventId: String)   // agregar aquí
}
```

En `App/AppRootView.swift`, agregar el `case` al `navigationDestination`.

---

## Checklist

- [ ] Domain no importa SwiftUI. Foundation solo donde es necesario.
- [ ] RepositoryImpl mapea DTOs a Entities — la Presentation nunca ve DTOs.
- [ ] ViewModel: `private(set)` en estado, `var` solo en bindings (`query`, `isPresenting...`)
- [ ] ViewModel usa `handle(_:)` como único punto de entrada desde la View
- [ ] `Status` enum por ViewModel: `.idle`, `.loading`, `.loaded`, `.failure(String)`
- [ ] Module registra ViewModels con `registerLazySingleton`, DataSources con `registerFactory`
- [ ] Sin lógica de negocio en Views — solo rendering y disparo de Intents

---

## Convenciones de naming

| Tipo | Convención | Ejemplo |
|------|-----------|---------|
| Entities | Sustantivos en inglés | `Ticket`, `Attendee` |
| Use Cases | Verbo + sustantivo | `FetchTicketsUseCase` |
| Repository protocol | Sustantivo + Repository | `TicketsRepository` |
| Repository impl | Protocol + Impl | `TicketsRepositoryImpl` |
| ViewModel | Feature + ViewModel | `TicketsViewModel` |
| Intent enum | Feature + Intent | `TicketsIntent` |
| Module | Feature + Module | `TicketsModule` |

Strings de usuario y comentarios en español. Código en inglés.
