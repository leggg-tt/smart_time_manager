import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_time_block.dart'show UserTimeBlock;
import '../models/enums.dart';
import '../providers/time_block_provider.dart';

// 定义AddTimeBlockDialog类(有状态的Widget类)
class AddTimeBlockDialog extends StatefulWidget {
  final UserTimeBlock? timeBlock;

  // 构造函数
  const AddTimeBlockDialog({
    Key? key,
    this.timeBlock,
  }) : super(key: key);

  @override
  _AddTimeBlockDialogState createState() => _AddTimeBlockDialogState();
}

class _AddTimeBlockDialogState extends State<AddTimeBlockDialog> {
  // 全局KEY,用于验证表单输入
  final _formKey = GlobalKey<FormState>();
  // 文本输入控制器，管理输入框的文本
  final _nameController = TextEditingController();
  // 文本输入控制器，管理输入框的文本
  final _descriptionController = TextEditingController();

  // 时间选择器的默认值
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  // 工作日,默认周一到周五
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // Default Monday to Friday
  // 能量水平和专注度的默认值
  EnergyLevel _energyLevel = EnergyLevel.medium;
  FocusLevel _focusLevel = FocusLevel.medium;
  // 适合的任务类别、优先级和能量水平列表
  List<TaskCategory> _suitableCategories = [];
  List<Priority> _suitablePriorities = [Priority.medium];
  List<EnergyLevel> _suitableEnergyLevels = [EnergyLevel.medium];
  Color _selectedColor = Colors.blue;

  // 可选颜色列表
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
  ];

  // 初始化方法
  @override
  void initState() {
    super.initState();
    if (widget.timeBlock != null) {
      _loadTimeBlock(widget.timeBlock!);
    }
  }

  // 加载数据块数据
  void _loadTimeBlock(UserTimeBlock block) {
    // 设置文本控制器的默认值
    _nameController.text = block.name;
    _descriptionController.text = block.description ?? '';

    // 解析开始时间(格式：HH:mm)
    final startParts = block.startTime.split(':');
    _startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );

    // 解析结束时间
    final endParts = block.endTime.split(':');
    _endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    // 复制列表和枚举值,使用List.from()创建新列表避免引用问题
    _selectedDays = List.from(block.daysOfWeek);
    _energyLevel = block.energyLevel;
    _focusLevel = block.focusLevel;
    _suitableCategories = List.from(block.suitableCategories);
    _suitablePriorities = List.from(block.suitablePriorities);
    _suitableEnergyLevels = List.from(block.suitableEnergyLevels);
    // 将十六进制颜色字符串转换为Color对象
    _selectedColor = Color(int.parse(block.color.replaceAll('#', '0xFF')));
  }

  // 资源释放,防止内存泄漏
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 构建UI
  @override
  Widget build(BuildContext context) {
    // 判断是否为编辑模式
    final isEditing = widget.timeBlock != null;

    // 返回Dialog组件
    return Dialog(
      child: Container(
        // 设置最大宽度为500像素
        constraints: const BoxConstraints(maxWidth: 500),
        // 使内容可以滚动(SingleChildScrollView)
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              // 绑定表单key
              key: _formKey,
              child: Column(
                // 让Column只占用必要空间
                mainAxisSize: MainAxisSize.min,
                // 子组件左对齐
                crossAxisAlignment: CrossAxisAlignment.start,
                // 根据模式显示不同标题
                children: [
                  Text(
                    isEditing ? 'Edit Time Block' : 'Add Time Block',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // 基本信息
                  TextFormField(
                    // 绑定名称输入控制器
                    controller: _nameController,
                    decoration: const InputDecoration(
                      // 标签
                      labelText: 'Time Block Name',
                      // 提示文字
                      hintText: 'e.g., Morning Golden Hours',
                      // 边框样式
                      border: OutlineInputBorder(),
                    ),
                    // 验证器函数,返回null表示验证通过
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter time block name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Describe characteristics of this time period',
                      border: OutlineInputBorder(),
                    ),
                    // 最多输入两行
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // 时间选择器
                  Row(
                    // 横向排列两个时间选择器
                    children: [
                      // 子组件平分剩余空间
                      Expanded(
                        // 调用自定义时间选择方法
                        child: _buildTimeSelector(
                          context,
                          'Start Time',
                          _startTime,
                              (time) => setState(() => _startTime = time),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          context,
                          'End Time',
                          _endTime,
                              (time) => setState(() => _endTime = time),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 星期选择器
                  Text(
                    'Days of Week',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  // 调用星期选择器构建方法
                  _buildWeekdaySelector(),
                  const SizedBox(height: 24),

                  // 时间块特性选择
                  Text(
                    'Time Block Characteristics',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown<EnergyLevel>(
                          'Energy Level',
                          _energyLevel,
                          // 获取枚举的所有值
                          EnergyLevel.values,
                              // 选择变化时的回调函数
                              (value) => setState(() => _energyLevel = value!),
                              // 获取显示名称的函数
                              (level) => level.displayName,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown<FocusLevel>(
                          'Focus Level',
                          _focusLevel,
                          FocusLevel.values,
                              (value) => setState(() => _focusLevel = value!),
                              (level) => level.displayName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 任务类型选择器
                  Text(
                    'Suitable Task Types',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  // 自动换行排列子组件
                  Wrap(
                    // 子组件间距
                    spacing: 8,
                    // map函数遍历所有任务类别
                    children: TaskCategory.values.map((category) {
                      // 返回可选标签组件
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(category.icon),
                            const SizedBox(width: 4),
                            Text(category.displayName),
                          ],
                        ),
                        // 选择状态改变时的处理逻辑
                        selected: _suitableCategories.contains(category),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _suitableCategories.add(category);
                            } else {
                              _suitableCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 优先级选择
                  Text(
                    'Suitable Task Priorities',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: Priority.values.map((priority) {
                      return FilterChip(
                        label: Text(priority.displayName),
                        // 选择状态改变时的处理逻辑
                        selected: _suitablePriorities.contains(priority),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _suitablePriorities.add(priority);
                            } else {
                              _suitablePriorities.remove(priority);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 颜色选择
                  Text(
                    'Display Color',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    // map函数遍历所有颜色
                    children: _colorOptions.map((color) {
                      // 提供点击效果
                      return InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        // 圆形颜色选择器
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            // 选中的颜色显示黑色的边框
                            border: _selectedColor == color
                                ? Border.all(width: 3, color: Colors.black)
                                : null,
                          ),
                          // 选中的颜色显示白色勾号
                          child: _selectedColor == color
                              ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 操作按钮
                  Row(
                    // 按钮右对齐
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 取消按钮关闭对话框
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        // 提交按钮调用提交方法
                        onPressed: _submitTimeBlock,
                        // 根据模式不同显示不同文字
                        child: Text(isEditing ? 'Save Changes' : 'Add Time Block'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 时间选择器构建方法
  Widget _buildTimeSelector(
      BuildContext context,
      String label,
      TimeOfDay time,
      Function(TimeOfDay) onChanged,
      ) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false), // 改为12小时制
              child: child!,
            );
          },
        );
        // 如果用户选择了时间,调用回调
        if (picked != null) {
          onChanged(picked);
        }
      },
      // 提供输入框样式
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 确保两位数显示
            Text(
              '${time.hour.toString().padLeft(2, '0')}:'
                  '${time.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Icon(Icons.access_time),
          ],
        ),
      ),
    );
  }

  // 星期选择器构建方法
  Widget _buildWeekdaySelector() {
    // 星期缩写数组
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // 改为英文缩写

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // List.generate生成7个组件
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isSelected = _selectedDays.contains(dayNumber);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(dayNumber);
              } else {
                _selectedDays.add(dayNumber);
                // 选中后保持排序
                _selectedDays.sort();
              }
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // 根据选中后来控制颜色
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                weekdays[index],
                // 选中之后加粗
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // 下拉选择器构建
  Widget _buildDropdown<T>(
      String label,
      T value,
      List<T> items,
      Function(T?) onChanged,
      // getLabel函数获取显示文本
      String Function(T) getLabel,
      ) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        // 创建下拉菜单项
        return DropdownMenuItem(
          value: item,
          child: Text(getLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // 提交表单方法
  Future<void> _submitTimeBlock() async {
    // 验证表单,验证失败则返回
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    if (_suitableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one suitable task type')),
      );
      return;
    }

    final timeBlock = UserTimeBlock(
      id: widget.timeBlock?.id,
      name: _nameController.text,
      startTime: '${_startTime.hour.toString().padLeft(2, '0')}:'
          '${_startTime.minute.toString().padLeft(2, '0')}',
      endTime: '${_endTime.hour.toString().padLeft(2, '0')}:'
          '${_endTime.minute.toString().padLeft(2, '0')}',
      daysOfWeek: _selectedDays,
      energyLevel: _energyLevel,
      focusLevel: _focusLevel,
      suitableCategories: _suitableCategories,
      suitablePriorities: _suitablePriorities,
      suitableEnergyLevels: _suitableEnergyLevels,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      // 将Color转换为十六进制字符串,转为16进制,去掉前两位（透明度）
      color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
      isActive: widget.timeBlock?.isActive ?? true,
      isDefault: widget.timeBlock?.isDefault ?? false,
      createdAt: widget.timeBlock?.createdAt,
    );

    // try-catch处理异步操作
    try {
      // context.read()获取Provider实例
      final provider = context.read<TimeBlockProvider>();

      // 根据模式执行不同操作
      if (widget.timeBlock != null) {
        // 更新现有时间块
        await provider.updateTimeBlock(timeBlock);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time block updated')),
        );
      } else {
        await provider.addTimeBlock(timeBlock);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time block added')),
        );
      }

      // 错误处理，显示红色错误消息
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}