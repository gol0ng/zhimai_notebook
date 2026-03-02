import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/log_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('应用版本'),
            subtitle: const Text('1.0.0'),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('调试日志'),
            subtitle: const Text('查看应用日志'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLogs(context),
          ),

          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('清空日志'),
            onTap: () {
              LogService.instance.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已清空')),
              );
              setState(() {});
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('关于'),
            subtitle: const Text('致迈笔记 - 手写笔记应用'),
          ),
        ],
      ),
    );
  }

  void _showLogs(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _LogsPage(),
      ),
    );
  }
}

class _LogsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logs = LogService.instance.logs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('调试日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制日志',
            onPressed: () {
              final logText = LogService.instance.getLogsAsString();
              Clipboard.setData(ClipboardData(text: logText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已复制到剪贴板')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清空日志',
            onPressed: () {
              LogService.instance.clear();
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text('暂无日志'),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _LogTile(log: log);
              },
            ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogEntry log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(log.level);

    return ExpansionTile(
      leading: Icon(
        _getLevelIcon(log.level),
        color: color,
        size: 20,
      ),
      title: Text(
        log.message,
        style: TextStyle(
          fontSize: 13,
          color: color,
        ),
      ),
      subtitle: Text(
        _formatTime(log.timestamp),
        style: const TextStyle(fontSize: 11),
      ),
      children: [
        if (log.error != null || log.stackTrace != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.error != null)
                  SelectableText(
                    log.error!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                if (log.stackTrace != null)
                  SelectableText(
                    log.stackTrace!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
