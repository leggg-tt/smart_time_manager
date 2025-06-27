import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_time_block.dart'show UserTimeBlock;
import '../models/enums.dart';
import '../providers/time_block_provider.dart';

class AddTimeBlockDialog extends StatefulWidget {
  final UserTimeBlock? timeBlock;

  const AddTimeBlockDialog({
    Key? key,
    this.timeBlock,
  }) : super(key: key);

  @override
  _AddTimeBlockDialogState createState() => _AddTimeBlockDialogState();
}

class _AddTimeBlockDialogState extends State<AddTimeBlockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // 默认周一到周五
  EnergyLevel _energyLevel = EnergyLevel.medium;
  FocusLevel _focusLevel = FocusLevel.medium;
  List<TaskCategory> _suitableCategories = [];
  List<Priority> _suitablePriorities = [Priority.medium];
  List<EnergyLevel> _suitableEnergyLevels = [EnergyLevel.medium];
  Color _selectedColor = Colors.blue;

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

  @override
  void initState() {
    super.initState();
    if (widget.timeBlock != null) {
      _loadTimeBlock(widget.timeBlock!);
    }
  }

  void _loadTimeBlock(UserTimeBlock block) {
    _nameController.text = block.name;
    _descriptionController.text = block.description ?? '';

    final startParts = block.startTime.split(':');
    _startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );

    final endParts = block.endTime.split(':');
    _endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    _selectedDays = List.from(block.daysOfWeek);
    _energyLevel = block.energyLevel;
    _focusLevel = block.focusLevel;
    _suitableCategories = List.from(block.suitableCategories);
    _suitablePriorities = List.from(block.suitablePriorities);
    _suitableEnergyLevels = List.from(block.suitableEnergyLevels);
    _selectedColor = Color(int.parse(block.color.replaceAll('#', '0xFF')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.timeBlock != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? '编辑时间块' : '添加时间块',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // 基本信息
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '时间块名称',
                      hintText: '例如：早晨黄金时间',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入时间块名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '描述（可选）',
                      hintText: '描述这个时间段的特点',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // 时间范围
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeSelector(
                          context,
                          '开始时间',
                          _startTime,
                              (time) => setState(() => _startTime = time),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          context,
                          '结束时间',
                          _endTime,
                              (time) => setState(() => _endTime = time),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 适用星期
                  Text(
                    '适用星期',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildWeekdaySelector(),
                  const SizedBox(height: 24),

                  // 时间块特性
                  Text(
                    '时间块特性',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown<EnergyLevel>(
                          '能量水平',
                          _energyLevel,
                          EnergyLevel.values,
                              (value) => setState(() => _energyLevel = value!),
                              (level) => level.displayName,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown<FocusLevel>(
                          '专注度',
                          _focusLevel,
                          FocusLevel.values,
                              (value) => setState(() => _focusLevel = value!),
                              (level) => level.displayName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 适合的任务类型
                  Text(
                    '适合的任务类型',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TaskCategory.values.map((category) {
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(category.icon),
                            const SizedBox(width: 4),
                            Text(category.displayName),
                          ],
                        ),
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

                  // 适合的优先级
                  Text(
                    '适合的任务优先级',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: Priority.values.map((priority) {
                      return FilterChip(
                        label: Text(priority.displayName),
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
                    '显示颜色',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _colorOptions.map((color) {
                      return InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: _selectedColor == color
                                ? Border.all(width: 3, color: Colors.black)
                                : null,
                          ),
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitTimeBlock,
                        child: Text(isEditing ? '保存修改' : '添加时间块'),
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
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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

  Widget _buildWeekdaySelector() {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                _selectedDays.sort();
              }
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                weekdays[index],
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

  Widget _buildDropdown<T>(
      String label,
      T value,
      List<T> items,
      Function(T?) onChanged,
      String Function(T) getLabel,
      ) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(getLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _submitTimeBlock() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个星期')),
      );
      return;
    }

    if (_suitableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一种适合的任务类型')),
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
      color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
      isActive: widget.timeBlock?.isActive ?? true,
      isDefault: widget.timeBlock?.isDefault ?? false,
      createdAt: widget.timeBlock?.createdAt,
    );

    try {
      final provider = context.read<TimeBlockProvider>();
      if (widget.timeBlock != null) {
        await provider.updateTimeBlock(timeBlock);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('时间块已更新')),
        );
      } else {
        await provider.addTimeBlock(timeBlock);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('时间块已添加')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}