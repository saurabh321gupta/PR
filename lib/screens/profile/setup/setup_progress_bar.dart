import 'package:flutter/material.dart';

class SetupProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const SetupProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 28, top: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted
                    ? const Color(0xFFE91E63)
                    : Colors.grey.shade200,
              ),
            ),
          );
        }),
      ),
    );
  }
}
