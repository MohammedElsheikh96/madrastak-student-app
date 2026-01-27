class AzureADConfig {
  static const String clientId = '085e344b-69bb-414e-bdaf-9d844a251168';
  static const String tenantId = 'e4396007-25d4-437c-895d-c317ddb4a259';
  static const String authority =
      'https://login.microsoftonline.com/e4396007-25d4-437c-895d-c317ddb4a259';

  // For Flutter mobile apps, use custom scheme redirect URI
  static const String redirectUri = 'msauth://com.madrastak.masr/callback';
  static const String callbackUrlScheme = 'msauth';

  static const List<String> scopes = ['openid', 'profile', 'email'];
  static const bool enabled = true;
}

class ApiConfig {
  static const String baseUrl =
      'https://mfm-student.madrasetna.net/api'; // Update with your actual API URL

  // Tawasol API for notifications and social features
  static const String tawasolApiUrl =
      'https://twassol-api.madrasetna.net/twassolApi';
}

class FirebaseConfig {
  static const String apiKey = 'AIzaSyCPYJhJg8KI4wkYj4a_Gc7N7vkgigdVMW8';
  static const String authDomain = 'tawasol-261fe.firebaseapp.com';
  static const String projectId = 'tawasol-261fe';
  static const String messagingSenderId = '510282064190';
  static const String appId = '1:510282064190:web:374afe24e098bfe13f0c6f';
}
