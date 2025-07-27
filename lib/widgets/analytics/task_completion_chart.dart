import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// 定义TaskCompletionChart有状态组件
class TaskCompletionChart extends StatefulWidget {
  final Map<String, dynamic> data;

  // 构造函数
  const TaskCompletionChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<TaskCompletionChart> createState() => _TaskCompletionChartState();
}

class _TaskCompletionChartState extends State<TaskCompletionChart>
    // 状态类混入SingleTickerProviderStateMixin
    with SingleTickerProviderStateMixin {
  // late表示这些变量会在initState中初始化
  // 控制动画的执行
  late AnimationController _animationController;
  // 定义动画的数值变化
  late Animation<double> _animation;

  // 初始化动画控制器
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      // 动画持续1500毫秒
      duration: const Duration(milliseconds: 1500),
      // 将当前State作为TickerProvider,用于同步动画帧
      vsync: this,
    );
    // 创建动画数值
    _animation = Tween<double>(
      // 定义动画的起始值（0）和结束值（完成率）
      begin: 0,
      end: widget.data['completionRate'] as double,
      // 应用缓动曲线
    ).animate(CurvedAnimation(
      parent: _animationController,
      // 开始和结束时慢,中间快的动画曲线
      curve: Curves.easeInOut,
    ));
    // 启动动画,从起始值向结束值播放
    _animationController.forward();
  }

  // 清理资源,避免内存泄漏
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // build方法
  @override
  Widget build(BuildContext context) {
    final completed = widget.data['completedTasks'] as int;  // 提取已完成任务数
    final total = widget.data['totalTasks'] as int;  // 提取总任务数
    final pending = total - completed;  // 计算待完成任务数

    // 返回Card组件
    return Card(
      // 较小的阴影效果
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        // 12像素圆角
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 左侧：饼图
            // 监听动画变化并重建子组件
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return SizedBox(
                  // 创建80x80像素的容器,使用Stack叠加布局
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 配置饼图
                      PieChart(
                        PieChartData(
                          startDegreeOffset: -90,  // 从12点钟方向开始绘制
                          sectionsSpace: 0,  // 扇形之间没有间隔
                          centerSpaceRadius: 25,  // 中心空白半径25像素
                          sections: [
                            // 定义两个扇形
                            PieChartSectionData(
                              // 已完成部分
                              value: _animation.value,
                              title: '',
                              // 使用主题色
                              color: Theme.of(context).colorScheme.primary,
                              radius: 15,
                            ),
                            PieChartSectionData(
                              // 未完成部分
                              value: 100 - _animation.value,
                              title: '',
                              // 使用浅灰色
                              color: Colors.grey.shade200,
                              // 环的厚度为15像素
                              radius: 15,
                            ),
                          ],
                        ),
                      ),
                      // 在饼图中心显示百分比
                      Text(
                        '${_animation.value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // 右侧：统计信息
            Expanded(
              child: Column(
                // Column只占用必要的垂直空间
                mainAxisSize: MainAxisSize.min,
                // 左对齐
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Completion',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 创建三个统计项,均匀分布
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCompactStat('Total', total, Colors.blue),  // 总任务数（蓝色）
                      _buildCompactStat('Done', completed, Colors.green),  // 已完成（绿色）
                      _buildCompactStat('Todo', pending, Colors.orange),  // 待完成（橙色）
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 统计项构建
  Widget _buildCompactStat(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        // 标签文字
        Text(
          label,
          style: TextStyle(
            // 11像素字号
            fontSize: 11,
            // 使用主题的bodySmall颜色,70%透明度
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}