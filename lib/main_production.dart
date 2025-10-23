import 'app/app.dart';
import 'core/bootstrap.dart';

void main() {
  Bootstrap.production(() async => const App());
}
