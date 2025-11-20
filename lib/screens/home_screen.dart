import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../services/stream_monitor_service.dart';
import 'alarm_history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    // 윈도우 닫기 방지
    if (Platform.isWindows) {
      print('🪟 윈도우 닫기 이벤트 - 대신 숨김 처리');
      // 닫기 대신 윈도우 숨김
      await windowManager.hide();
      // windowManager.close()나 destroy()를 호출하지 않음
    }
  }

  @override
  Future<void> onWindowEvent(String eventName) async {
    print('🪟 윈도우 이벤트: $eventName');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text('스타드림 트위캐스 안 놓치려 만든 앱')
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '알람 히스토리',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlarmHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '설정',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '모든 스트림 즉시 확인',
            onPressed: () {
              context.read<StreamMonitorService>().manualCheckAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 스트림을 확인하는 중...')),
              );
            },
          ),
        ],
      ),
      body: Consumer<StreamMonitorService>(
        builder: (context, service, child) {
          return Column(
            children: [
              // 알람 제어 섹션
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.volume_up),
                        const SizedBox(width: 8),
                        const Text(
                          '알람 볼륨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(service.alarmVolume * 100).round()}%',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Slider(
                      value: service.alarmVolume,
                      onChanged: (value) {
                        service.updateVolume(value);
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                    ),
                    if (service.isAlarmPlaying)
                      ElevatedButton.icon(
                        onPressed: () => service.stopAlarm(),
                        icon: const Icon(Icons.stop),
                        label: const Text('알람 중지'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),

              // 스트림 목록
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final stream = service.streams[index];
                    return _StreamCard(
                      index: index,
                      stream: stream,
                      onUrlChanged: (url) => service.updateStreamUrl(index, url),
                      onToggleMonitoring: () => service.toggleMonitoring(index),
                      onManualCheck: () => service.manualCheckStream(index),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreamCard extends StatefulWidget {
  final int index;
  final dynamic stream; // StreamInfo 타입
  final Function(String) onUrlChanged;
  final VoidCallback onToggleMonitoring;
  final VoidCallback onManualCheck;

  const _StreamCard({
    required this.index,
    required this.stream,
    required this.onUrlChanged,
    required this.onToggleMonitoring,
    required this.onManualCheck,
  });

  @override
  State<_StreamCard> createState() => _StreamCardState();
}

class _StreamCardState extends State<_StreamCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.stream.url);
  }

  @override
  void didUpdateWidget(_StreamCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream.url != oldWidget.stream.url) {
      _controller.text = widget.stream.url;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (!widget.stream.isMonitoring) {
      return Colors.grey;
    }
    if (widget.stream.isLive == null) {
      return Colors.orange;
    }
    return widget.stream.isLive ? Colors.green : Colors.red;
  }

  String _getStatusText() {
    if (!widget.stream.isMonitoring) {
      return '모니터링 안 함';
    }
    if (widget.stream.isLive == null) {
      return '확인 중...';
    }
    return widget.stream.isLive ? '라이브' : '오프라인';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Stream ${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '트위캐스트 URL',
                hintText: 'https://twitcasting.tv/username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: widget.onUrlChanged,
              enabled: !widget.stream.isMonitoring,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.stream.url.isEmpty
                        ? null
                        : widget.onToggleMonitoring,
                    icon: Icon(
                      widget.stream.isMonitoring ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      widget.stream.isMonitoring ? '모니터링 중지' : '모니터링 시작',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.stream.isMonitoring
                          ? Colors.red
                          : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.stream.url.isEmpty || !widget.stream.isMonitoring
                      ? null
                      : widget.onManualCheck,
                  icon: const Icon(Icons.refresh),
                  tooltip: '지금 확인',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
