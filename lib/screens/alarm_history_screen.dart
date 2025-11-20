import 'package:flutter/material.dart';
import '../models/alarm_history.dart';
import '../services/alarm_history_service.dart';

/// 알람 히스토리 화면
class AlarmHistoryScreen extends StatefulWidget {
  const AlarmHistoryScreen({super.key});

  @override
  State<AlarmHistoryScreen> createState() => _AlarmHistoryScreenState();
}

class _AlarmHistoryScreenState extends State<AlarmHistoryScreen> {
  List<AlarmHistory> _history = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// 히스토리 데이터 로드
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await AlarmHistoryService.getHistory();
    final stats = await AlarmHistoryService.getStatistics();

    setState(() {
      _history = history;
      _statistics = stats;
      _isLoading = false;
    });
  }

  /// 전체 히스토리 삭제 확인 다이얼로그
  Future<void> _confirmClearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('히스토리 전체 삭제'),
        content: const Text('모든 알람 히스토리를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AlarmHistoryService.clearHistory();
      _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 히스토리가 삭제되었습니다')),
        );
      }
    }
  }

  /// 단일 항목 삭제
  Future<void> _deleteItem(int index) async {
    await AlarmHistoryService.deleteHistoryAt(index);
    _loadHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('히스토리 항목이 삭제되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 히스토리'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '전체 삭제',
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '알람 히스토리가 없습니다',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 통계 카드
                    _buildStatisticsCard(),
                    const Divider(height: 1),

                    // 히스토리 리스트
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            return _buildHistoryItem(item, index);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  /// 통계 정보 카드
  Widget _buildStatisticsCard() {
    final totalAlarms = _statistics['totalAlarms'] ?? 0;
    final todayAlarms = _statistics['todayAlarms'] ?? 0;
    final weekAlarms = _statistics['weekAlarms'] ?? 0;
    final mostActiveStream = _statistics['mostActiveStream'];
    final mostActiveCount = _statistics['mostActiveStreamCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 통계',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('전체', totalAlarms.toString(), Colors.blue),
                _buildStatItem('오늘', todayAlarms.toString(), Colors.green),
                _buildStatItem('7일', weekAlarms.toString(), Colors.orange),
              ],
            ),
            if (mostActiveStream != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '가장 활발한 스트림: $mostActiveStream ($mostActiveCount회)',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 통계 항목
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// 히스토리 항목 위젯
  Widget _buildHistoryItem(AlarmHistory item, int index) {
    return Dismissible(
      key: Key('${item.timestamp.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(index),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.wasAlarmTriggered ? Colors.red : Colors.grey,
          child: Icon(
            item.wasAlarmTriggered ? Icons.notifications_active : Icons.info,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item.userId,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.streamUrl,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item.getFormattedTime(),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: item.wasAlarmTriggered
            ? const Chip(
                label: Text('알람', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.redAccent,
                labelStyle: TextStyle(color: Colors.white),
                padding: EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              )
            : null,
      ),
    );
  }
}
