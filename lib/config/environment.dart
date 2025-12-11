/// Environment configuration for API endpoints
/// 
/// To switch environments:
/// 1. Change `currentEnvironment` to your desired env (development, staging, or production)
/// 2. For local dev, update `localApiUrl` if your server uses a different port
/// 3. Rebuild the app
/// 
/// Environment hierarchy:
/// - DEVELOPMENT: Local testing on your machine
/// - STAGING: Test server (test.tficorg.org)
/// - PRODUCTION: Live production server (tficorg.org)

enum AppEnvironment {
  development,
  staging,
  production,
}

class Environment {
  // ⚠️ CHANGE THIS TO SWITCH ENVIRONMENTS
  static const AppEnvironment currentEnvironment = AppEnvironment.staging;
  
  // Local development API (your localhost)
  static const String localApiUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String localApiUrl = 'http://localhost:5000/api'; // iOS simulator
  // static const String localApiUrl = 'http://192.168.1.XXX:5000/api'; // Physical device (replace with your PC's IP)
  
  // Staging API (for testing)
  static const String stagingApiUrl = 'https://api-staging.tficorg.org/api';
  
  // Production API
  static const String productionApiUrl = 'https://api.tficorg.org/api';
  
  // Current API URL based on environment
  static String get apiUrl {
    switch (currentEnvironment) {
      case AppEnvironment.development:
        return localApiUrl;
      case AppEnvironment.staging:
        return stagingApiUrl;
      case AppEnvironment.production:
        return productionApiUrl;
    }
  }
  
  // Environment info
  static String get environmentName {
    switch (currentEnvironment) {
      case AppEnvironment.development:
        return 'DEVELOPMENT';
      case AppEnvironment.staging:
        return 'STAGING';
      case AppEnvironment.production:
        return 'PRODUCTION';
    }
  }
  
  static bool get isDevelopment => currentEnvironment == AppEnvironment.development;
  static bool get isStaging => currentEnvironment == AppEnvironment.staging;
  static bool get isProduction => currentEnvironment == AppEnvironment.production;
}
