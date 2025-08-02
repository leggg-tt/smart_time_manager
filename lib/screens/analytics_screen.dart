import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';
import '../models/enums.dart';
import '../widgets/analytics/task_completion_chart.dart';
import '../widgets/analytics/category_distribution_chart.dart';
import '../widgets/analytics/productivity_heatmap.dart';
import '../widgets/analytics/daily_trend_chart.dart';
import '../widgets/analytics/priority_analysis_card.dart';
import '../widgets/analytics/time_utilization_card.dart';
import '../widgets/file_export_dialog.dart';  // 【新增导入】

// 定义一个有状态的AnalyticsScreen组件
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

// 状态类定义
class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // _analyticsService：分析服务实例,用于获取统计数据
  final AnalyticsService _analyticsService = AnalyticsService();

  // _startDate：统计开始日期,默认为30天前
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  // _endDate：统计结束日期,默认为今天
  DateTime _endDate = DateTime.now();
  // _selectedPeriod：当前选中的时间段,默认为'30d'（30天）
  String _selectedPeriod = '30d';

  // 构建UI
  @override
  Widget build(BuildContext context) {
    // 使用Scaffold作为页面基础结构
    return Scaffold(
      appBar: AppBar(
        // 标题设置
        title: const Text('Analytics'),
        // 背景色
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 【新增开始】- 添加导出按钮
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const FileExportDialog(),
              );
            },
          ),
          // 【新增结束】
          // 在AppBar右侧添加一个弹出菜单按钮
          PopupMenuButton<String>(
            // initialValue:设置初始选中值
            initialValue: _selectedPeriod,
            // onSelected:选择项时的回调函数
            onSelected: _onPeriodChanged,
            itemBuilder: (context) => [
              // 提供4个选项：7天、30天、90天、自定义范围
              const PopupMenuItem(value: '7d', child: Text('Last 7 days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 days')),
              const PopupMenuItem(value: '90d', child: Text('Last 90 days')),
              const PopupMenuItem(value: 'custom', child: Text('Custom range')),
            ],
            child: Padding(
              // 按钮显示内容:日期图标+当前选中的时间段文本
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.date_range),
                  const SizedBox(width: 8),
                  Text(_getPeriodText()),
                ],
              ),
            ),
          ),
        ],
      ),
      // 主要内容
      body: RefreshIndicator(
        // 下拉刷新组件,刷新时调用setState重建UI
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 总览信息部分
              _buildOverviewSection(),
              const SizedBox(height: 24),

              // Task Completion Chart部分
              _buildSectionTitle('Task Completion'),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                // 使用FutureBuilder异步加载数据
                child: FutureBuilder<Map<String, dynamic>>(
                  // 调用getTaskCompletionStats获取任务完成统计
                  future: _analyticsService.getTaskCompletionStats(
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      // 数据加载中显示进度指示器
                      return const Center(child: CircularProgressIndicator());
                    }
                    // 数据加载完成后显示TaskCompletionChart组件
                    return TaskCompletionChart(data: snapshot.data!);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Daily Trend Chart部分
              _buildSectionTitle('Daily Activity Trend'),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  // 调用getDailyTaskPattern获取每日任务模式数据
                  future: _analyticsService.getDailyTaskPattern(
                    // _getDaysDifference()计算开始和结束日期之间的天数
                    days: _getDaysDifference(),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return DailyTrendChart(data: snapshot.data!);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Category Distribution部分
              _buildSectionTitle('Task Categories'),
              const SizedBox(height: 8),
              SizedBox(
                // 显示任务分类分布图
                height: 240,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _analyticsService.getCategoryDistribution(
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      // 以饼图显示
                      return const Center(child: CircularProgressIndicator());
                    }
                    // 展示不同类别任务的占比
                    return CategoryDistributionChart(data: snapshot.data!);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Priority Analysis部分
              _buildSectionTitle('Priority Analysis'),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                // 显示优先级分析
                future: _analyticsService.getPriorityDistribution(
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    // 将数据列表映射为多个PriorityAnalysisCard
                    children: snapshot.data!
                        .map((data) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PriorityAnalysisCard(data: data),
                    ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Productivity Heatmap部分
              _buildSectionTitle('Peak Productivity Hours'),
              const SizedBox(height: 8),
              SizedBox(
                // 显示生产力热力图
                height: 320,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _analyticsService.getPeakProductivityHours(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // 展示一周中每个时段的生产力水平,帮助用户识别自己的高效时段
                    return ProductivityHeatmap(data: snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildOverviewSection方法
  Widget _buildOverviewSection() {
    return Column(
      children: [
        // 时间利用率卡片
        Row(
          // 创建一个水平布局容器
          children: [
            // 让子组件占满 Row 的可用宽度,确保卡片能够充分利用屏幕宽度
            Expanded(
              // 异步加载时间利用率统计数据
              child: FutureBuilder<Map<String, dynamic>>(
                // future参数调用分析服务的getTimeUtilizationStats方法
                future: _analyticsService.getTimeUtilizationStats(
                  // 传入开始和结束日期作为统计范围
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                builder: (context, snapshot) {
                  // 检查是否有数据,如果数据还未加载完成,显示一个加载卡片
                  if (!snapshot.hasData) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  // 数据加载完成后,返回TimeUtilizationCard组件
                  return TimeUtilizationCard(data: snapshot.data!);
                },
              ),
            ),
          ],
        ),
        // 行间距
        const SizedBox(height: 16),
        // 番茄钟统计卡片
        Row(
          children: [
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                // 调用getPomodoroStats获取番茄钟统计数据
                future: _analyticsService.getPomodoroStats(
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                builder: (context, snapshot) {
                  // 无数据时的处理不同
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  // 自定义卡片内容
                  final data = snapshot.data!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                // 图标
                                Icons.local_fire_department,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                // 标题
                                'Pomodoro Stats',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          // 统计数据行
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // 第一个统计项：总番茄钟数
                              _buildStatItem(
                                context,
                                '${data['totalPomodoros']}',  // 数值：总番茄钟数
                                'Pomodoros',  // 标签
                                Icons.timer,  // 图标：计时器
                              ),
                              // 第二个统计项：专注时间
                              _buildStatItem(
                                context,
                                '${(data['totalWorkHours'] as double).toStringAsFixed(1)}h',
                                'Focus Time',
                                Icons.schedule,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // _buildStatItem方法
  Widget _buildStatItem(
      // 构建单个统计项的UI
      BuildContext context,
      String value,
      String label,
      IconData icon,
      ) {
    return Column(
      // 垂直排列：图标、数值、标签
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // _buildSectionTitle方法
  Widget _buildSectionTitle(String title) {
    // 构建统一的区域标题样式
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // _onPeriodChanged方法
  // 处理时间段选择变化
  void _onPeriodChanged(String period) async {
    // 如果选择"custom"，显示日期范围选择器
    if (period == 'custom') {
      final picked = await showDateRangePicker(
        context: context,
        // 允许选择过去365天内的任意时间段
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      );
      if (picked != null) {
        // 选择后更新状态并重建UI
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
          _selectedPeriod = period;
        });
      }
    } else {
      // 处理预设时间段（7天、30天、90天）
      setState(() {
        _selectedPeriod = period;
        _endDate = DateTime.now();
        switch (period) {
          case '7d':
            _startDate = _endDate.subtract(const Duration(days: 7));
            break;
          case '30d':
            _startDate = _endDate.subtract(const Duration(days: 30));
            break;
          case '90d':
            _startDate = _endDate.subtract(const Duration(days: 90));
            break;
        }
      });
    }
  }

  // _getPeriodText方法
  String _getPeriodText() {
    // 将时间段代码转换为显示文本
    switch (_selectedPeriod) {
      case '7d':
        return 'Last 7 days';
      case '30d':
        return 'Last 30 days';
      case '90d':
        return 'Last 90 days';
      case 'custom':
      // 使用DateFormat格式化日期
        final format = DateFormat('MMM d');
        return '${format.format(_startDate)} - ${format.format(_endDate)}';
      default:
        return 'Select period';
    }
  }

  // _getDaysDifference方法
  int _getDaysDifference() {
    return _endDate.difference(_startDate).inDays;
  }
}