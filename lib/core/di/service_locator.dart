import 'package:get_it/get_it.dart';
import '../dotenv/dotenv.dart';
import '../share/installed_apps_repository.dart';
final GetIt sl = GetIt.instance;
Future<void> setupServiceLocator() async {
  sl.registerLazySingleton(() => InstalledAppsRepository());
  sl.registerLazySingleton(() => DotEnv());
}