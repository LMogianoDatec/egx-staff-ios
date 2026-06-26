import Foundation

enum EventsModule {
    static func register() {
        // Data Sources
        sl.registerLazySingleton(EventsRemoteDataSource.self) {
            EventsRemoteDataSourceImpl(client: sl())
        }

        // Repository
        sl.registerLazySingleton(EventsRepository.self) {
            EventsRepositoryImpl(remote: sl())
        }

        // Use Cases
        sl.registerLazySingleton(FetchAssignedEventsUseCase.self) {
            FetchAssignedEventsUseCase(repository: sl())
        }

        // ViewModels
        sl.registerFactory(EventsViewModel.self) {
            EventsViewModel(fetchEvents: sl(), logger: sl())
        }
    }
}
