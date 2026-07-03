/// Wszystkie ścieżki w jednym miejscu — chroni przed literówkami przy
/// nawigacji. Używaj `AppRoutes.roomPath(42)` zamiast wpisywać string ręcznie.
class AppRoutes {
  const AppRoutes._();

  // Auth
  static const String login = 'login';
  static const String loginPath = '/login';
  static const String register = 'register';
  static const String registerPath = '/register';

  // Main
  static const String dashboard = 'dashboard';
  static const String dashboardPath = '/';
  static const String languages = 'languages';
  static const String languagesPath = '/languages';
  static const String profile = 'profile';
  static const String profilePath = '/profile';

  // Room + subpages
  static const String room = 'room';
  static const String roomPath = '/rooms/:roomId';
  static String roomFor(int roomId) => '/rooms/$roomId';

  static const String learning = 'learning';
  static String learningFor(int roomId) => '/rooms/$roomId/learning';

  static const String review = 'review';
  static String reviewFor(int roomId) => '/rooms/$roomId/review';

  static const String alphabet = 'alphabet';
  static String alphabetFor(int roomId) => '/rooms/$roomId/alphabet';
}
