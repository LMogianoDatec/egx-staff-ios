import Foundation

enum AuthModule {
    static func register() {
        // Data Sources
        sl.registerLazySingleton(AuthLocalDataSource.self) {
            AuthLocalDataSourceImpl(keychain: sl())
        }

        sl.registerLazySingleton(AuthRemoteDataSource.self) {
            AuthRemoteDataSourceImpl(client: sl())
        }

        // Repository
        sl.registerLazySingleton(AuthRepository.self) {
            AuthRepositoryImpl(remote: sl(), local: sl())
        }

        // Use Cases
        sl.registerLazySingleton(LoginUseCase.self) {
            LoginUseCase(repository: sl())
        }

        sl.registerLazySingleton(LogoutUseCase.self) {
            LogoutUseCase(repository: sl())
        }

        sl.registerLazySingleton(LoadSessionUseCase.self) {
            LoadSessionUseCase(repository: sl())
        }

        // ViewModels
        sl.registerFactory(LoginViewModel.self) {
            LoginViewModel(loginUseCase: sl())
        }
    }
}
