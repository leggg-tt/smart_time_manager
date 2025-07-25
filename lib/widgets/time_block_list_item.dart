import 'package:flutter/material.dart';
import '../models/user_time_block.dart';
import '../models/enums.dart';

// 定义一个无状态组件,用于显示单个时间块项目
class TimeBlockListItem extends StatelessWidget {
  final UserTimeBlock timeBlock;  // 时间块数据对象(必须)
  final VoidCallback? onTap;  // 可选的点击回调函数
  final VoidCallback? onToggle; // 可选的切换状态回调函数
  final VoidCallback? onDelete;  // 可选的删除回调函数

  // 构造函数
  const TimeBlockListItem({
    Key? key,
    required this.timeBlock,
    this.onTap,
    this.onToggle,
    this.onDelete,
  }) : super(key: key);

  // 重写父类方法,构建UI
  @override
  Widget build(BuildContext context) {
    // 将时间块颜色字符串转换为Flutter中对应的颜色对象
    final color = Color(int.parse(timeBlock.color.replaceAll('#', '0xFF')));

    // 返回一个卡片组件
    return Card(
      // 根据激活状态设置阴影(2是激活,0是未激活)
      elevation: timeBlock.isActive ? 2 : 0,
      // 水波纹动画组件
      child: InkWell(
        onTap: onTap,  // 点击事件
        borderRadius: BorderRadius.circular(12),  // 圆角12像素
        // 根据激活状态设置透明度
        child: Opacity(
          opacity: timeBlock.isActive ? 1.0 : 0.6,
          // 容器设置(内边距16像素)
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // 左边框
              border: Border(
                left: BorderSide(
                  color: color,
                  width: 4,
                ),
              ),
            ),
            // 使用垂直列布局,子元素左对齐
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 使用水平行布局,让子组件占用剩余空间
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                timeBlock.name,  // 显示时间块名称
                                // 主题样式
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // 如果是默认时间块,显示默认标识
                              if (timeBlock.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  // 透明度与圆角
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1), // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.1)
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,  // 字体大小
                                      // 颜色为主题色
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${timeBlock.startTime} - ${timeBlock.endTime}',  // 显示开始时间和结束时间
                            style: Theme.of(context).textTheme.bodyMedium,  // 使用 bodyMedium 文本样式
                          ),
                        ],
                      ),
                    ),

                    // 激活按钮,如果提供了onToggle回调,显示开关
                    if (onToggle != null)
                      // 绑定激活状态和切换事件
                      Switch(
                        value: timeBlock.isActive,
                        onChanged: (_) => onToggle!(),
                      ),
                    // 只有非默认时间块才显示删除按钮
                    if (onDelete != null && !timeBlock.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                        tooltip: 'Delete',
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // 星期显示,调用私有方法构建星期选择器
                _buildWeekdayChips(context),

                const SizedBox(height: 12),

                // 属性标签
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeatureChip(
                      context,
                      Icons.battery_full,  // 显示电池图标
                      'Energy: ${timeBlock.energyLevel.displayName}',  // 显示能量等级文本
                      _getEnergyColor(timeBlock.energyLevel),  // 根据能量等级获取对应颜色
                    ),
                    _buildFeatureChip(
                      context,
                      Icons.psychology,  // 显示大脑图标
                      'Focus: ${timeBlock.focusLevel.displayName}',  // 显示专注等级文本
                      Colors.indigo,  // 使用靛蓝色
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 适合的任务类型部分
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suitable Task Types',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      // 遍历适合的任务类别
                      children: timeBlock.suitableCategories.map((category) {
                        return Chip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.icon, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                category.displayName,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          // 密度紧凑
                          visualDensity: VisualDensity.compact,
                          // 最小化点击目标
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // 如果有描述且不为空，显示描述
                if (timeBlock.description != null && timeBlock.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    timeBlock.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 自定义星期选择器
  Widget _buildWeekdayChips(BuildContext context) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];  // 之后改一下,容易让用户混淆

    // 生成7个按钮,检查该天是否被选中
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isSelected = timeBlock.daysOfWeek.contains(dayNumber);

        // 圆形容器,32x32像素,选中时使用主题色,未选中使用表面变体色
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceVariant,  // 将surfaceVariant替换为 surfaceContainerHighest,但没有效果不知道为什么,可能是版本问题
            shape: BoxShape.circle,
          ),
          // 居中显示
          child: Center(
            child: Text(
              weekdays[index],
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  // 属性组件构建
  Widget _buildFeatureChip(
      BuildContext context,
      IconData icon,
      String label,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // 背景色使用传入颜色的10%透明度
        color: color.withOpacity(0.1),  // 现版本是withValues,后面如果出问题再更改:withValues(alpha: 0.1)
        borderRadius: BorderRadius.circular(16),  // 圆角
      ),
      // 组件内容
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 能量颜色映射
  Color _getEnergyColor(EnergyLevel level) {
    switch (level) {
      case EnergyLevel.high:
        return Colors.red;
      case EnergyLevel.medium:
        return Colors.orange;
      case EnergyLevel.low:
        return Colors.green;
    }
  }
}