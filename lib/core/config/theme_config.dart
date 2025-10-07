import 'package:flutter/material.dart';
import 'app_constants.dart';

/// 애플리케이션의 테마 설정을 관리하는 클래스
/// Material Design 3를 기반으로 한 다크 테마 정의
class ThemeConfig {
  /// 다크 테마 설정을 반환
  /// 애플리케이션 전체의 일관된 디자인을 위한 테마 정의
  static ThemeData get darkTheme {
    return ThemeData(
      // 기본 색상 설정
      primarySwatch: Colors.blue,

      // Material Design 3 사용
      useMaterial3: true,

      // 다크 모드 설정
      brightness: Brightness.dark,

      // Scaffold 기본 배경색
      scaffoldBackgroundColor: AppConstants.backgroundPrimary,

      // AppBar 테마 설정
      appBarTheme: const AppBarTheme(
        elevation: 0, // 그림자 제거
        backgroundColor: AppConstants.backgroundSecondary, // 배경색 설정
        centerTitle: true, // 제목 중앙 정렬
      ),

      // Card 위젯 테마 설정
      cardTheme: const CardThemeData(
        elevation: 4, // 그림자 깊이
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)), // 둥근 모서리
        ),
      ),
    );
  }
}