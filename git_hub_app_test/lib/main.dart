import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // 1. 앱 시작 전 .env 파일 로드
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

// --- Dio 설정 클래스 ---
class GitHubDio {
  static Dio getDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.github.com',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    // 인터셉터를 사용하여 모든 요청에 자동으로 토큰 삽입
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = dotenv.env['GITHUB_TOKEN'];
          options.headers['Authorization'] = 'Bearer $token';
          options.headers['Accept'] = 'application/vnd.github+json';
          
          print("🚀 API 요청 중: ${options.baseUrl}${options.path}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print("✅ 응답 성공: ${response.statusCode}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print("❌ 에러 발생: ${e.message}");
          return handler.next(e);
        },
      ),
    );

    return dio;
  }
}

// --- 메인 앱 위젯 ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GitHub API Study')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // 버튼 클릭 시 API 호출 테스트
              await testGitHubApi();
            },
            child: const Text('내 정보 가져오기 (콘솔 확인)'),
          ),
        ),
      ),
    );
  }

  // 실제 API 호출 함수
  Future<void> testGitHubApi() async {
    final dio = GitHubDio.getDio();
    try {
      // 인터셉터 덕분에 헤더 설정 없이 바로 호출 가능!
      final response = await dio.get('/user');
      
      print('--- 결과 데이터 ---');
      print('닉네임: ${response.data['login']}');
      print('이름: ${response.data['name']}');
      print('Bio: ${response.data['bio']}');
    } catch (e) {
      print('호출 실패: $e');
    }
  }
}