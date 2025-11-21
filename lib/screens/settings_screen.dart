import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stream_monitor_service.dart';

/// 설정 화면
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: Consumer<StreamMonitorService>(
        builder: (context, service, child) {
          return ListView(
            children: [
              // 알람 설정 섹션
              _buildSectionHeader('🔔 알람 설정'),

              _buildSliderTile(
                title: '알람 볼륨',
                subtitle: '알람 소리의 크기를 조절합니다',
                value: service.alarmVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                valueLabel: '${(service.alarmVolume * 100).toInt()}%',
                onChanged: (value) {
                  service.updateVolume(value);
                },
              ),

              const Divider(height: 1),

              // 네트워크 설정 섹션
              _buildSectionHeader('🌐 네트워크 설정'),

              _buildSliderTile(
                title: '재시도 횟수',
                subtitle: '네트워크 오류 시 재시도할 최대 횟수',
                value: service.maxRetries.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                valueLabel: '${service.maxRetries}회',
                onChanged: (value) {
                  service.updateMaxRetries(value.toInt());
                },
              ),

              _buildSliderTile(
                title: '재시도 간격',
                subtitle: '재시도 사이의 대기 시간',
                value: service.retryDelaySeconds.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                valueLabel: '${service.retryDelaySeconds}초',
                onChanged: (value) {
                  service.updateRetryDelay(value.toInt());
                },
              ),

              const Divider(height: 1),

              // 모니터링 설정 섹션
              _buildSectionHeader('⏱️ 모니터링 설정'),

              _buildSliderTile(
                title: '확인 간격',
                subtitle: '스트림 상태를 확인하는 주기',
                value: service.checkIntervalSeconds.toDouble(),
                min: 10,
                max: 300,
                divisions: 29,
                valueLabel: '${service.checkIntervalSeconds}초',
                onChanged: (value) {
                  service.updateCheckInterval(value.toInt());
                },
              ),

              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blue),
                title: const Text(
                  '주의사항',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  '확인 간격을 너무 짧게 설정하면 IP 차단의 위험이 있습니다. '
                  '권장값: 30초 이상',
                  style: TextStyle(fontSize: 12),
                ),
              ),

              const SizedBox(height: 24),

              // 현재 설정 요약
              _buildSummaryCard(service),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  /// 섹션 헤더
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  /// 슬라이더 타일
  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: valueLabel,
                  onChanged: onChanged,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  valueLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 현재 설정 요약 카드
  Widget _buildSummaryCard(StreamMonitorService service) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 현재 설정',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('알람 볼륨', '${(service.alarmVolume * 100).toInt()}%'),
            _buildSummaryRow('재시도 횟수', '${service.maxRetries}회'),
            _buildSummaryRow('재시도 간격', '${service.retryDelaySeconds}초'),
            _buildSummaryRow('확인 간격', '${service.checkIntervalSeconds}초'),
          ],
        ),
      ),
    );
  }

  /// 요약 행
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
