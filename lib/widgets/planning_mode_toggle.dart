import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/planning_mode_provider.dart';

class PlanningModeToggle extends ConsumerWidget {
  const PlanningModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlanning = ref.watch(planningModeProvider);
    final color = isPlanning ? Colors.orange : Colors.green;

    return FloatingActionButton.small(
      backgroundColor: color,
      onPressed: () {
        ref.read(planningModeProvider.notifier).state = !isPlanning;
      },
      tooltip: isPlanning ? 'Modo Planificación' : 'Modo Ejecución',
      child: Icon(
        isPlanning ? Icons.shield : Icons.flash_on,
        color: Colors.white,
      ),
    );
  }
}
