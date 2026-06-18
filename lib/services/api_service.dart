import 'package:dio/dio.dart';
import 'token_service.dart';
import '../utils/api_constants.dart';

class ApiService {
  final Dio dio;
  final TokenService tokenService;

  ApiService(this.tokenService) : dio = Dio() {
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    //Interceptors act as Middlemen

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.uri.toString().contains('open-meteo.com')) {
            return handler.next(options);
          }
          // Add Authorization header if access token is available

          final token = await tokenService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Check if the error is due to an unauthorized access and not from login or refresh endpoints
          if (e.response?.statusCode == 401 && 
              !e.requestOptions.path.contains('/auth/login') && 
              !e.requestOptions.path.contains('/auth/refresh')) {
            
            final refreshToken = await tokenService.getRefreshToken();
            if (refreshToken != null) {
              try {
                // Create a temporary Dio instance to avoid interceptor loop
                final tempDio = Dio();
                final response = await tempDio.post(
                  ApiConstants.refresh,
                  data: {
                    'refreshToken': refreshToken,
                    'expiresInMins': 30,
                  },
                  options: Options(headers: {'Content-Type': 'application/json'}),
                );
                
                final newAccessToken = response.data['token'] ?? response.data['accessToken'];
                final newRefreshToken = response.data['refreshToken'] ?? refreshToken;
                
                await tokenService.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken,
                );

                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                
                final cloneReq = await dio.request(
                  opts.path,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                  ),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(cloneReq);
              } catch (refreshError) {
                await tokenService.clearTokens();
                return handler.reject(e);
              }
            } else {
               await tokenService.clearTokens();
               return handler.reject(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}
