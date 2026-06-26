import Foundation

/// Extrae el `idn` (identityId) de un QR escaneado.
/// El QR es un token PASETO `vX.purpose.<payload b64url>.<footer>` cuyo payload
/// es JSON `{"identityId":"idn_...", ...}` seguido de la firma binaria.
/// También acepta un `idn_...` crudo por si el QR ya lo trae directo.
enum QRPayloadParser {
    static func extractIdn(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("idn_") { return trimmed }

        guard let obj = extractJSONObject(from: trimmed),
              let idn = obj["identityId"] as? String, !idn.isEmpty
        else { return nil }
        return idn
    }

    static func extractExpiry(from raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let obj = extractJSONObject(from: trimmed),
              let expString = obj["exp"] as? String
        else { return nil }
        return parseISO8601(expString)
    }

    // MARK: - Helpers

    private static func extractJSONObject(from trimmed: String) -> [String: Any]? {
        // PASETO: version.purpose.payload.footer? → necesitamos el payload (índice 2).
        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 3, let data = base64urlDecode(String(parts[2])) else { return nil }
        guard let jsonData = firstJSONObject(in: data),
              let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { return nil }
        return obj
    }

    private static func parseISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        // Truncar a 3 decimales si el servidor envía más (ej. 7 dígitos)
        let truncated = string.replacingOccurrences(of: #"(\.\d{3})\d+"#, with: "$1", options: .regularExpression)
        return formatter.date(from: truncated)
    }

    // MARK: - Helpers

    private static func base64urlDecode(_ s: String) -> Data? {
        var str = s.replacingOccurrences(of: "-", with: "+")
                   .replacingOccurrences(of: "_", with: "/")
        let pad = str.count % 4
        if pad != 0 { str += String(repeating: "=", count: 4 - pad) }
        return Data(base64Encoded: str)
    }

    /// Devuelve el primer objeto JSON `{...}` balanceado dentro de `data`,
    /// ignorando lo que venga después (p.ej. la firma de PASETO).
    private static func firstJSONObject(in data: Data) -> Data? {
        let bytes = [UInt8](data)
        guard let start = bytes.firstIndex(of: 0x7B) else { return nil } // '{'

        var depth = 0
        var inString = false
        var escaped = false
        var i = start
        while i < bytes.count {
            let b = bytes[i]
            if inString {
                if escaped { escaped = false }
                else if b == 0x5C { escaped = true }      // '\'
                else if b == 0x22 { inString = false }    // '"'
            } else {
                switch b {
                case 0x22: inString = true                // '"'
                case 0x7B: depth += 1                      // '{'
                case 0x7D:                                  // '}'
                    depth -= 1
                    if depth == 0 {
                        return Data(bytes[start...i])
                    }
                default: break
                }
            }
            i += 1
        }
        return nil
    }
}
