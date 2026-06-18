import '../models/user_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'token_service.dart';

class AuthService {
  final ApiService apiService;
  final TokenService tokenService;

  AuthService(this.apiService, this.tokenService);

  Future<UserModel?> login(String username, String password) async {
    try {
      final response = await apiService.dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
          'expiresInMins': 30,
        },
      );
      
      final token = response.data['token'] ?? response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];
      
      await tokenService.saveTokens(
        accessToken: token, 
        refreshToken: refreshToken ?? token
      );

      return UserModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Login failed');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await tokenService.getAccessToken();
      if (token == null) return null;

      final response = await apiService.dio.get(ApiConstants.authMe);
      return UserModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await tokenService.clearTokens();
  }
}
