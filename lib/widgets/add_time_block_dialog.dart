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
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // Default Monday to Friday
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
                    isEditing ? 'Edit Time Block' : 'Add Time Block', // 原来是 '编辑时间块' : '添加时间块'
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Basic information
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Time Block Name',              // 原来是 '时间块名称'
                      hintText: 'e.g., Morning Golden Hours',    // 原来是 '例如：早晨黄金时间'
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter time block name';   // 原来是 '请输入时间块名称'
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',       // 原来是 '描述（可选）'
                      hintText: 'Describe characteristics of this time period', // 原来是 '描述这个时间段的特点'
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Time range
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeSelector(
                          context,
                          'Start Time',                           // 原来是 '开始时间'
                          _startTime,
                              (time) => setState(() => _startTime = time),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          context,
                          'End Time',                             // 原来是 '结束时间'
                          _endTime,
                              (time) => setState(() => _endTime = time),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Applicable weekdays
                  Text(
                    'Days of Week',                               // 原来是 '适用星期'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildWeekdaySelector(),
                  const SizedBox(height: 24),

                  // Time block characteristics
                  Text(
                    'Time Block Characteristics',                 // 原来是 '时间块特性'
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown<EnergyLevel>(
                          'Energy Level',                         // 原来是 '能量水平'
                          _energyLevel,
                          EnergyLevel.values,
                              (value) => setState(() => _energyLevel = value!),
                              (level) => level.displayName,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown<FocusLevel>(
                          'Focus Level',                          // 原来是 '专注度'
                          _focusLevel,
                          FocusLevel.values,
                              (value) => setState(() => _focusLevel = value!),
                              (level) => level.displayName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Suitable task types
                  Text(
                    'Suitable Task Types',                        // 原来是 '适合的任务类型'
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

                  // Suitable task priorities
                  Text(
                    'Suitable Task Priorities',                   // 原来是 '适合的任务优先级'
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

                  // Color selection
                  Text(
                    'Display Color',                              // 原来是 '显示颜色'
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

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),             // 原来是 '取消'
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitTimeBlock,
                        child: Text(isEditing ? 'Save Changes' : 'Add Time Block'), // 原来是 '保存修改' : '添加时间块'
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
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false), // 改为12小时制
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
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // 改为英文缩写

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
        const SnackBar(content: Text('Please select at least one day')), // 原来是 '请至少选择一个星期'
      );
      return;
    }

    if (_suitableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one suitable task type')), // 原来是 '请至少选择一种适合的任务类型'
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
          const SnackBar(content: Text('Time block updated')), // 原来是 '时间块已更新'
        );
      } else {
        await provider.addTimeBlock(timeBlock);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time block added')), // 原来是 '时间块已添加'
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: $e'),           // 原来是 '操作失败: $e'
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}