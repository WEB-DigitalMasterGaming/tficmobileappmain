/// Environment configuration for API endpoints
/// 
/// To run against local development server:
/// 1. Change `isDevelopment` to `true`
/// 2. Update `localApiUrl` if your local server uses a different port
/// 3. Run the app
/// 
/// To switch back to production:
/// 1. Change `isDevelopment` to `false`
/// 2. Rebuild the app

class Environment {
  // ⚠️ CHANGE THIS TO SWITCH BETWEEN DEV AND PROD
  static const bool isDevelopment = false; // Set to true for local testing
  
  // Local development API (your localhost)
  static const String localApiUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String localApiUrl = 'http://localhost:5000/api'; // iOS simulator
  // static const String localApiUrl = 'http://192.168.1.XXX:5000/api'; // Physical device (replace with your PC's IP)
  
  // Staging API (for testing)
  static const String stagingApiUrl = 'https://api-staging.tficorg.org/api';
  
  // Production API
  static const String productionApiUrl = 'https://api.tficorg.org/api';
  
  // Current API URL based on environment
  static String get apiUrl => isDevelopment ? localApiUrl : stagingApiUrl;
  
  // Debug info
  static String get environmentName => isDevelopment ? 'DEVELOPMENT' : 'STAGING';
}
