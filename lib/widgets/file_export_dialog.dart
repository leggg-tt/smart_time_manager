import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/file_export_service.dart';

class FileExportDialog extends StatefulWidget {
  const FileExportDialog({Key? key}) : super(key: key);

  @override
  State<FileExportDialog> createState() => _FileExportDialogState();
}

class _FileExportDialogState extends State<FileExportDialog> {
  final FileExportService _exportService = FileExportService();

  // 导出类型
  int _exportType = 0; // 0: Tasks CSV, 1: Analytics Report

  // 日期范围
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // 任务状态过滤
  bool _includeCompleted = true;
  bool _includePending = true;
  bool _includeScheduled = true;

  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.save_alt, size: 24),
          const SizedBox(width: 8),
          const Text('Export Data'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 导出类型选择
            Text(
              'Export Type',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Tasks CSV'),
                  icon: Icon(Icons.table_chart, size: 16),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Report'),
                  icon: Icon(Icons.analytics, size: 16),
                ),
              ],
              selected: {_exportType},
              onSelectionChanged: (value) {
                setState(() {
                  _exportType = value.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // 日期范围选择
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('MMM dd').format(_startDate)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('MMM dd').format(_endDate)),
                  ),
                ),
              ],
            ),

            // 任务状态过滤（仅CSV导出时显示）
            if (_exportType == 0) ...[
              const SizedBox(height: 16),
              Text(
                'Include Tasks',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Completed'),
                value: _includeCompleted,
                onChanged: (value) {
                  setState(() {
                    _includeCompleted = value ?? true;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Pending'),
                value: _includePending,
                onChanged: (value) {
                  setState(() {
                    _includePending = value ?? true;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Scheduled'),
                value: _includeScheduled,
                onChanged: (value) {
                  setState(() {
                    _includeScheduled = value ?? true;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],

            const SizedBox(height: 16),

            // 文件位置说明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'File Location',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: _exportService.getExportDirectoryPath(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Files will be saved to:',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      snapshot.data!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: snapshot.data!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Path copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 查看已导出文件按钮
            TextButton.icon(
              onPressed: _showExportedFiles,
              icon: const Icon(Icons.history),
              label: const Text('View Exported Files'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _handleExport,
          icon: _isExporting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.save, size: 18),
          label: Text(_isExporting ? 'Exporting...' : 'Export'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _handleExport() async {
    // 验证
    if (_exportType == 0 && !_includeCompleted && !_includePending && !_includeScheduled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one task status to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      String filePath;

      if (_exportType == 0) {
        // 导出任务CSV
        filePath = await _exportService.exportTasksToFile(
          startDate: _startDate,
          endDate: _endDate,
          includeCompleted: _includeCompleted,
          includePending: _includePending,
          includeScheduled: _includeScheduled,
        );
      } else {
        // 导出分析报告
        filePath = await _exportService.exportAnalyticsReportToFile(
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();

        // 显示成功对话框
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text('Export Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('File saved successfully!'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File path:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        filePath,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You can access this file using a file manager app.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: filePath));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File path copied to clipboard'),
                    ),
                  );
                },
                child: const Text('Copy Path'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // 显示已导出的文件列表
  void _showExportedFiles() async {
    final files = await _exportService.listExportedFiles();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported Files'),
        content: SizedBox(
          width: double.maxFinite,
          child: files.isEmpty
              ? const Center(
            child: Text('No exported files found'),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = file.path.split('/').last;
              final stat = file.statSync();
              final modifiedDate = DateFormat('MMM dd, HH:mm').format(stat.modified);

              return ListTile(
                leading: Icon(
                  fileName.endsWith('.csv') ? Icons.table_chart : Icons.description,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(fileName),
                subtitle: Text('Modified: $modifiedDate'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete File'),
                        content: Text('Delete "$fileName"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _exportService.deleteExportFile(file.path);
                      Navigator.of(context).pop();
                      _showExportedFiles();
                    }
                  },
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: file.path));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File path copied to clipboard'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}