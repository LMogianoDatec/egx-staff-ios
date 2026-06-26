import Foundation

enum CoreModule {
    static func register(apiConfiguration: APIConfiguration = .mock) {
        sl.registerLazySingleton(APIConfiguration.self) { apiConfiguration }
        sl.registerLazySingleton(KeychainStorage.self) { KeychainStorage() }
        sl.registerLazySingleton(LoggerService.self) { OSLogger(category: "network") }

        sl.registerLazySingleton(APIClient.self) {
            DefaultAPIClient(
                configuration: sl(),
                interceptors: [
                    AuthInterceptor { await sl(AuthRepository.self).currentAccessToken() },
                    UnauthorizedInterceptor(),
                    LoggingInterceptor(logger: sl(), logBody: _isDebugAssertConfiguration())
                ],
                logger: sl()
            )
        }
    }
}
