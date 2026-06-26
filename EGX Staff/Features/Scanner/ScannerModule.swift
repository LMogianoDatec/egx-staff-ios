import Foundation

enum ScannerModule {
    static func register() {
        // Data Sources
        sl.registerLazySingleton(ScannerRemoteDataSource.self) {
            ScannerRemoteDataSourceImpl(client: sl())
        }

        // Repository
        sl.registerLazySingleton(ScannerRepository.self) {
            ScannerRepositoryImpl(remote: sl())
        }

        // Use Cases
        sl.registerLazySingleton(CheckAccessUseCase.self) {
            CheckAccessUseCase(repository: sl())
        }
        sl.registerLazySingleton(ConfirmAttendanceUseCase.self) {
            ConfirmAttendanceUseCase(repository: sl())
        }

        // ScannerViewModel se construye en la vista con el `eventId` seleccionado.
    }
}
