# 002: Cero dependencias externas (no SPM, no CocoaPods)

## Status: Accepted

## Decisión

El proyecto usa únicamente frameworks de Apple. No se agrega ningún paquete de Swift Package Manager ni CocoaPods.

## Contexto

El proyecto es una app de control de acceso de dominio acotado: autenticación, lista de eventos, escaneo QR. Todas estas capacidades están cubiertas por:

- `SwiftUI` + `Swift Observation` — UI y estado
- `URLSession` — networking
- `AVFoundation` — cámara y QR
- `Security` (SecItem) — Keychain
- `OSLog` — logging

Las dependencias externas más comunes consideradas y descartadas:

| Paquete | Capacidad | Por qué no |
|---------|-----------|------------|
| Alamofire | Networking | URLSession + interceptor chain propio es suficiente |
| Kingfisher | Image caching | `CachedAsyncImage.swift` cubre el caso de uso |
| Swinject | DI | `ServiceLocator.swift` (100 líneas) es suficiente |
| The Composable Architecture | State management | MVVM-I es más simple para este dominio |

## Consecuencias

- **Positivo**: Tiempo de build más rápido (sin resolución de paquetes).
- **Positivo**: Sin riesgo de breaking changes de terceros entre versiones.
- **Positivo**: Sin surface de ataque de supply chain.
- **Positivo**: El proyecto abre y corre con `open .xcodeproj` sin pasos adicionales.
- **Negativo**: Más código propio a mantener (networking, caching, DI).
- **Límite**: Reconsiderar si surge necesidad de capacidades complejas no cubiertas por Apple frameworks (e.g., analytics SDKs requeridos por el cliente, Bluetooth HID, etc.).
