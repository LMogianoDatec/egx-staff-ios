import Foundation

struct BaseResponse<T: Decodable>: Decodable {
    let status: Int?
    let message: String?
    let data: T
}
