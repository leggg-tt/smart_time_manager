import 'package:flutter/material.dart';

// 定义TimeUtilizationCard组件,这是一个有状态的组件
class TimeUtilizationCard extends StatefulWidget {
  // 接收数据,包含计划时间,实际时间和利用率
  final Map<String, dynamic> data;

  // 构造函数
  const TimeUtilizationCard({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<TimeUtilizationCard> createState() => _TimeUtilizationCardState();
}

// State类,混入SingleTickerProviderStateMixin用于动画
class _TimeUtilizationCardState extends State<TimeUtilizationCard>
    with SingleTickerProviderStateMixin {
  // 动画控制器,控制动画的播放
  late AnimationController _animationController;
  // 进度条动画,用于显示时间利用率的动画效果
  late Animation<double> _progressAnimation;

  // 动画控制器初始化
  @override
  void initState() {
    super.initState();
    // 创建动画控制器,设置动画持续时间为1.5秒
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 从传入的数据中获取利用率
    final utilizationRate = widget.data['utilizationRate'] as double;
    // 限制进度条最大值为1.0(100%)
    final clampedRate = utilizationRate.clamp(0, 100) / 100;

    // 创建进度动画,从0渐变到实际利用率
    _progressAnimation = Tween<double>(
      begin: 0,
      end: clampedRate,
    ).animate(CurvedAnimation(
      parent: _animationController,
      // 使用缓入缓出的动画曲线
      curve: Curves.easeInOut,
    ));

    // 启动动画
    _animationController.forward();
  }

  @override
  void dispose() {
    // 释放动画控制器,防止内存泄漏
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 从数据中提取所需值
    final plannedHours = widget.data['plannedHours'] as double;  // 计划小时数
    final actualHours = widget.data['actualHours'] as double;  // 实际小时数
    final utilizationRate = widget.data['utilizationRate'] as double;  // 利用率
    final isOvertime = utilizationRate > 100;  // 判断是否超时（利用率超过100%）

    // 返回卡片组件
    return Card(
      // 卡片阴影高度
      elevation: 4,
      // 圆角
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // 渐变背景,从左上到右下
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 图标容器
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timer,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 标题和副标题
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Utilization',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Actual vs Planned Time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 如果超时,显示超时标签
                  if (isOvertime)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_off, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Overtime',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // 动画统计数据行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 计划时间统计
                  _buildAnimatedStat(
                    context,
                    'Planned',
                    plannedHours,
                    Colors.blue,
                    Icons.event_note,
                    // 无延迟
                    0,
                  ),
                  // 实际时间统计
                  _buildAnimatedStat(
                    context,
                    'Actual',
                    actualHours,
                    // 超时显示橙色,否则绿色
                    isOvertime ? Colors.orange : Colors.green,
                    isOvertime ? Icons.timer_off : Icons.check_circle,
                    // 200ms 延迟开始动画
                    200,
                  ),
                  // 效率统计
                  _buildAnimatedStat(
                    context,
                    'Efficiency',
                    utilizationRate,
                    // 根据效率获取颜色
                    _getEfficiencyColor(utilizationRate),
                    isOvertime ? Icons.trending_down : Icons.trending_up,
                    // 400ms延迟开始动画
                    400,
                    // 显示为百分比
                    isPercentage: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 进度条部分
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 进度条标题行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Usage',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      // 使用AnimatedBuilder监听动画变化
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Text(
                            '${actualHours.toStringAsFixed(1)}h / ${plannedHours.toStringAsFixed(1)}h',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 进度条动画
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // 进度条背景
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          // 填充的进度条
                          FractionallySizedBox(
                            // 根据动画值设置宽度比例
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                // 渐变色
                                gradient: LinearGradient(
                                  colors: [
                                    isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate),
                                    (isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate)).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                // 阴影效果
                                boxShadow: [
                                  BoxShadow(
                                    color: (isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate)).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 如果超时,在100%位置显示红线标记
                          if (isOvertime)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: Colors.red.withOpacity(0.5),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  // 如果超时,显示0%和100%标记
                  if (isOvertime) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                        Text(
                          '100%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // 提示信息容器
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate)).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOvertime ? Icons.warning_amber : _getEfficiencyIcon(utilizationRate),
                      color: isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 主要提示信息
                          Text(
                            // 传入plannedHours参数
                            isOvertime ? _getOvertimeMessage(utilizationRate) : _getEfficiencyMessage(utilizationRate, plannedHours),
                            style: TextStyle(
                              color: isOvertime ? Colors.orange : _getEfficiencyColor(utilizationRate),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // 如果超时,显示具体超时信息
                          if (isOvertime) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Overtime: ${(actualHours - plannedHours).toStringAsFixed(1)}h (${(utilizationRate - 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建动画统计数据的辅助方法
  Widget _buildAnimatedStat(
      BuildContext context,
      String label,  // 标签文本
      double value,  // 数值
      Color color,  // 颜色
      IconData icon,  // 图标
      // 动画延迟（毫秒）
      int delay, {
        // 是否显示为百分比
        bool isPercentage = false,
      }) {
    // 使用TweenAnimationBuilder创建数值动画
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),  // 从0动画到目标值
      duration: Duration(milliseconds: 1000 + delay),  // 动画持续时间包含延迟
      curve: Curves.easeOutCubic,  // 缓出立方曲线,动画开始快后面慢
      builder: (context, animatedValue, child) {
        return Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              // 根据是否为百分比显示不同格式
              isPercentage
                  ? '${animatedValue.toStringAsFixed(1)}%'
                  : '${animatedValue.toStringAsFixed(1)}h',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        );
      },
    );
  }

  // 根据效率获取对应颜色
  Color _getEfficiencyColor(double rate) {
    if (rate > 100) return Colors.orange.shade600;  // 超时：橙色
    if (rate >= 90) return Colors.green.shade600;  // 90-100%：绿色（优秀）
    if (rate >= 70) return Colors.blue.shade600;  // 70-89%：蓝色（良好）
    if (rate >= 50) return Colors.amber.shade600;  // 50-69%：琥珀色（一般）
    return Colors.red.shade600;  // 低于50%：红色（较差）
  }

  // 根据效率获取对应图标
  IconData _getEfficiencyIcon(double rate) {
    if (rate >= 90 && rate <= 100) return Icons.sentiment_very_satisfied;  // 非常满意
    if (rate >= 70) return Icons.sentiment_satisfied;  // 满意
    if (rate >= 50) return Icons.sentiment_neutral;  // 中性
    return Icons.sentiment_dissatisfied;  // 不满意
  }

  // 根据效率生成提示信息
  String _getEfficiencyMessage(double rate, double plannedHours) {
    // 添加特殊情况处理：没有计划任务
    if (plannedHours == 0) {
      return 'No tasks were planned for this period.';
    }

    if (rate >= 90 && rate <= 100) return 'Excellent time management! Keep it up!';
    if (rate >= 70) return 'Good utilization. Room for improvement.';
    if (rate >= 50) return 'Consider optimizing your time estimates.';
    return 'Time estimates may need adjustment.';
  }

  // 生成超时提示信息
  String _getOvertimeMessage(double rate) {
    final overtimePercent = rate - 100;
    if (overtimePercent <= 20) return 'Slightly over time. Consider better estimation.';
    if (overtimePercent <= 50) return 'Significant overtime. Review task complexity.';
    return 'Major overtime! Break down tasks into smaller pieces.';
  }
}