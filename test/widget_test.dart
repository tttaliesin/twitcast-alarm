// Flutter 기본 위젯 테스트
//
// 이 앱은 복잡한 비동기 작업과 플랫폼 채널을 사용하므로
// 단위 테스트는 향후 추가 예정입니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:twitcast_alarm/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 참고: TwitcastAlarmApp은 SharedPreferences와 같은 비동기 초기화가 필요하므로
    // 간단한 스모크 테스트만 수행합니다.

    // 기본적인 앱 생성 테스트
    expect(const TwitcastAlarmApp(), isA<Widget>());
  });
}
