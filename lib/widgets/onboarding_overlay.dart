import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingOverlay extends StatefulWidget {
  final Widget child;
  final String screen;

  const OnboardingOverlay({
    Key? key,
    required this.child,
    required this.screen,
  }) : super(key: key);

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  bool _showGuide = false;
  int _currentStep = 0;

  final Map<String, List<GuideStep>> _guides = {
    'time_blocks': [
      GuideStep(
        title: 'Understanding Time Blocks',
        description: 'Time blocks represent your energy and focus levels throughout the day. Morning blocks typically have high energy, while afternoon blocks may have lower energy.',
        icon: Icons.access_time,
      ),
      GuideStep(
        title: 'Energy Levels Explained',
        description: '🔋 High: Best for creative and complex tasks\n🔋 Medium: Good for routine work\n🔋 Low: Suitable for simple tasks',
        icon: Icons.battery_charging_full,
      ),
      GuideStep(
        title: 'Smart Matching',
        description: 'Tasks are automatically matched to time blocks based on:\n• Task priority & energy needs\n• Your focus levels\n• Task categories',
        icon: Icons.psychology,
      ),
    ],
    'task_creation': [
      GuideStep(
        title: 'Task Attributes',
        description: 'Each task has:\n• Priority (High/Medium/Low)\n• Energy Required\n• Focus Level Needed\n• Category (Creative/Analytical/etc)',
        icon: Icons.task_alt,
      ),
      GuideStep(
        title: 'Best Practices',
        description: '✨ High priority + High energy tasks → Morning blocks\n📧 Communication tasks → Low energy periods\n🎨 Creative work → High focus blocks',
        icon: Icons.lightbulb,
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenGuide = prefs.getBool('seen_${widget.screen}_guide') ?? false;

    if (!hasSeenGuide && _guides.containsKey(widget.screen)) {
      setState(() {
        _showGuide = true;
      });
    }
  }

  Future<void> _completeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_${widget.screen}_guide', true);

    setState(() {
      _showGuide = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showGuide && _guides.containsKey(widget.screen))
          _buildGuideOverlay(),
      ],
    );
  }

  Widget _buildGuideOverlay() {
    final steps = _guides[widget.screen]!;
    final currentStep = steps[_currentStep];

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  currentStep.icon,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  currentStep.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  currentStep.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _completeGuide,
                      child: const Text('Skip'),
                    ),
                    Row(
                      children: [
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentStep--;
                              });
                            },
                            child: const Text('Previous'),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_currentStep < steps.length - 1) {
                              setState(() {
                                _currentStep++;
                              });
                            } else {
                              _completeGuide();
                            }
                          },
                          child: Text(
                            _currentStep < steps.length - 1 ? 'Next' : 'Got it!',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    steps.length,
                        (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentStep
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuideStep {
  final String title;
  final String description;
  final IconData icon;

  GuideStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}