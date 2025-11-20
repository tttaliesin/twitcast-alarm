import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설정 화면
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 설정값
  double _alarmVolume = 0.8;
  int _maxRetries = 3;
  int _retryDelaySeconds = 2;
  int _checkIntervalSeconds = 30;

  // 설정 키
  static const String _volumeKey = 'alarm_volume';
  static const String _retriesKey = 'max_retries';
  static const String _retryDelayKey = 'retry_delay_seconds';
  static const String _checkIntervalKey = 'check_interval_seconds';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 설정 로드
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _alarmVolume = prefs.getDouble(_volumeKey) ?? 0.8;
      _maxRetries = prefs.getInt(_retriesKey) ?? 3;
      _retryDelaySeconds = prefs.getInt(_retryDelayKey) ?? 2;
      _checkIntervalSeconds = prefs.getInt(_checkIntervalKey) ?? 30;
      _isLoading = false;
    });
  }

  /// 설정 저장
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_volumeKey, _alarmVolume);
    await prefs.setInt(_retriesKey, _maxRetries);
    await prefs.setInt(_retryDelayKey, _retryDelaySeconds);
    await prefs.setInt(_checkIntervalKey, _checkIntervalSeconds);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('설정이 저장되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 기본값으로 초기화
  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정 초기화'),
        content: const Text('모든 설정을 기본값으로 되돌리시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _alarmVolume = 0.8;
        _maxRetries = 3;
        _retryDelaySeconds = 2;
        _checkIntervalSeconds = 30;
      });

      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '기본값으로 초기화',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: ListView(
        children: [
          // 알람 설정 섹션
          _buildSectionHeader('🔔 알람 설정'),

          _buildSliderTile(
            title: '알람 볼륨',
            subtitle: '알람 소리의 크기를 조절합니다',
            value: _alarmVolume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            valueLabel: '${(_alarmVolume * 100).toInt()}%',
            onChanged: (value) {
              setState(() {
                _alarmVolume = value;
              });
            },
          ),

          const Divider(height: 1),

          // 네트워크 설정 섹션
          _buildSectionHeader('🌐 네트워크 설정'),

          _buildSliderTile(
            title: '재시도 횟수',
            subtitle: '네트워크 오류 시 재시도할 최대 횟수',
            value: _maxRetries.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            valueLabel: '$_maxRetries회',
            onChanged: (value) {
              setState(() {
                _maxRetries = value.toInt();
              });
            },
          ),

          _buildSliderTile(
            title: '재시도 간격',
            subtitle: '재시도 사이의 대기 시간',
            value: _retryDelaySeconds.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            valueLabel: '$_retryDelaySeconds초',
            onChanged: (value) {
              setState(() {
                _retryDelaySeconds = value.toInt();
              });
            },
          ),

          const Divider(height: 1),

          // 모니터링 설정 섹션
          _buildSectionHeader('⏱️ 모니터링 설정'),

          _buildSliderTile(
            title: '확인 간격',
            subtitle: '스트림 상태를 확인하는 주기',
            value: _checkIntervalSeconds.toDouble(),
            min: 10,
            max: 300,
            divisions: 29,
            valueLabel: '$_checkIntervalSeconds초',
            onChanged: (value) {
              setState(() {
                _checkIntervalSeconds = value.toInt();
              });
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

          // 저장 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('설정 저장'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 현재 설정 요약
          _buildSummaryCard(),

          const SizedBox(height: 32),
        ],
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
  Widget _buildSummaryCard() {
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
            _buildSummaryRow('알람 볼륨', '${(_alarmVolume * 100).toInt()}%'),
            _buildSummaryRow('재시도 횟수', '$_maxRetries회'),
            _buildSummaryRow('재시도 간격', '$_retryDelaySeconds초'),
            _buildSummaryRow('확인 간격', '$_checkIntervalSeconds초'),
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
