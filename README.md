# EGX Staff

Control de acceso QR para personal autorizado en eventos EGX. Operadores gestionan sesiones y validan asistencia de invitados mediante escaneo de códigos QR.

---

## Requisitos

| Herramienta | Versión mínima |
|-------------|----------------|
| Xcode | 16.0+ |
| iOS Deployment Target | 17.6 |
| Swift | 5.9+ |
| macOS | Sonoma 14+ |

Sin dependencias externas — solo frameworks de Apple.

---

## Quickstart

```bash
git clone <repo-url>
open "EGX Staff/EGX Staff.xcodeproj"
# Cmd+R para correr
```

Sin `pod install` ni `swift package resolve`.

Para apuntar a un servidor distinto, editar `Config/Debug.xcconfig`:

```
API_BASE_URL = https://tu-servidor.ejemplo.com
```

Para activar mock data (sin red): cambiar `Injection.setup(apiConfiguration: .mock)` en `EGXStaffApp.swift`.

---

## Estructura

```
EGX Staff/
├── App/                   # Punto de entrada, ciclo de vida, AuthState
├── Core/
│   ├── DI/                # ServiceLocator (GetIt-style)
│   ├── Navigation/        # AppRouter con Route enum tipado
│   ├── Networking/        # APIClient, Endpoint, interceptores, retry
│   ├── Storage/           # Keychain abstraction
│   ├── DesignSystem/      # Tokens de color, componentes base
│   └── Haptics/
└── Features/
    ├── Auth/              # Login, sesión, logout
    ├── Events/            # Lista de eventos y sesiones
    └── Scanner/           # Cámara, QR, validación y confirmación
```

Cada feature: `<Feature>Module.swift` · `Application/` · `Data/` · `Domain/` · `Presentation/`

---

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [Arquitectura](docs/architecture.md) | Capas, patrones, ViewModel, DI, navegación |
| [Networking](docs/networking.md) | APIClient, Endpoint, interceptores, retry, logging |
| [Feature: Auth](docs/features/auth.md) | Login, almacenamiento de sesión, expiración |
| [Feature: Events](docs/features/events.md) | Lista de eventos, sesiones, selectedEvent pattern |
| [Feature: Scanner](docs/features/scanner.md) | Flujo QR, estados, PASETO, confirmación |
| [Cómo agregar un feature](CONTRIBUTING.md) | Estructura, pasos, checklist |
| [Decisiones de arquitectura](docs/adr/) | ADRs — el por qué detrás de cada decisión |

---

## Autores

- Leonardo Mogiano (lmogiano@datec.com.bo)

---

## Estado

| Feature | Estado |
|---------|--------|
| Login con device_name + password | ✅ |
| Almacenamiento seguro en Keychain | ✅ |
| Detección de sesión expirada (launch + foreground + 401) | ✅ |
| Lista de eventos con búsqueda y pull-to-refresh | ✅ |
| Escaneo QR con AVCaptureSession | ✅ |
| Validación de acceso (check + confirm) | ✅ |
| Soporte PASETO tokens | ✅ |
| Logging de requests en debug | ✅ |
| Navegación centralizada (AppRouter) | ✅ |

## Deuda técnica

| Ítem | Prioridad |
|------|-----------|
| Tests unitarios (UseCases, ViewModels) | Alta |
| Release xcconfig → URL de producción real | Alta |
| Token refresh (actualmente dura ~1 semana) | Media |
| Android (`AndroidStudioProjects/EGXStaff`) | Alta |
| Tests de UI | Baja |
| Internacionalización | Baja |
