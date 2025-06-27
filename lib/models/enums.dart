// 任务优先级
enum Priority {
  low,    // 低
  medium, // 中
  high    // 高
}

// 任务状态
enum TaskStatus {
  pending,    // 待处理
  scheduled,  // 已安排
  inProgress, // 进行中
  completed,  // 已完成
  cancelled   // 已取消
}

// 能量等级
enum EnergyLevel {
  low,    // 低能量
  medium, // 中等能量
  high    // 高能量
}

// 专注度等级
enum FocusLevel {
  light,  // 轻度专注
  medium, // 中度专注
  deep    // 深度专注
}

// 任务类型
enum TaskCategory {
  creative,      // 创造性
  analytical,    // 分析性
  routine,       // 事务性
  communication  // 沟通协作
}

// 扩展方法：获取中文显示名称
extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.low:
        return '低';
      case Priority.medium:
        return '中';
      case Priority.high:
        return '高';
    }
  }

  int get value {
    switch (this) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
    }
  }
}

extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.creative:
        return '创造性';
      case TaskCategory.analytical:
        return '分析性';
      case TaskCategory.routine:
        return '事务性';
      case TaskCategory.communication:
        return '沟通协作';
    }
  }

  String get icon {
    switch (this) {
      case TaskCategory.creative:
        return '🎨';
      case TaskCategory.analytical:
        return '📊';
      case TaskCategory.routine:
        return '📝';
      case TaskCategory.communication:
        return '👥';
    }
  }
}

extension EnergyLevelExtension on EnergyLevel {
  String get displayName {
    switch (this) {
      case EnergyLevel.low:
        return '低';
      case EnergyLevel.medium:
        return '中';
      case EnergyLevel.high:
        return '高';
    }
  }

  int get value {
    switch (this) {
      case EnergyLevel.low:
        return 1;
      case EnergyLevel.medium:
        return 2;
      case EnergyLevel.high:
        return 3;
    }
  }
}

extension FocusLevelExtension on FocusLevel {
  String get displayName {
    switch (this) {
      case FocusLevel.light:
        return '轻度';
      case FocusLevel.medium:
        return '中度';
      case FocusLevel.deep:
        return '深度';
    }
  }

  int get value {
    switch (this) {
      case FocusLevel.light:
        return 1;
      case FocusLevel.medium:
        return 2;
      case FocusLevel.deep:
        return 3;
    }
  }
}