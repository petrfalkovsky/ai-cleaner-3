import 'app/app.dart';
import 'core/bootstrap.dart';

void main() {
  Bootstrap.development(() async => const App());
}
