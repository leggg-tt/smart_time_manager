import 'package:flutter/material.dart';
import 'dart:async';

/// 任务搜索框组件
/// 提供搜索输入功能，包含防抖动和清除按钮
class TaskSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Duration debounceDuration;

  const TaskSearchBar({
    super.key,
    required this.onSearchChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<TaskSearchBar> createState() => _TaskSearchBarState();
}

class _TaskSearchBarState extends State<TaskSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    // 监听文本变化
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 处理文本变化，实现防抖动
  void _onTextChanged() {
    final text = _controller.text;

    // 更新清除按钮显示状态
    setState(() {
      _showClear = text.isNotEmpty;
    });

    // 取消之前的定时器
    _debounceTimer?.cancel();

    // 创建新的定时器，实现防抖动
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearchChanged(text);
    });
  }

  // 清除搜索内容
  void _clearSearch() {
    _controller.clear();
    widget.onSearchChanged('');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _showClear
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: _clearSearch,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          isDense: true,
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          // 立即触发搜索，不等待防抖
          _debounceTimer?.cancel();
          widget.onSearchChanged(value);
        },
      ),
    );
  }
}