class AppConfig {
  /// ozie-api base URL (keep trailing slash).
  static const String baseUrl = 'https://demo.orderezee.com/ozie-api/index.php?route=';

  /// Set in main() after Firebase.initializeApp() succeeds.
  static bool firebaseReady = false;
}
