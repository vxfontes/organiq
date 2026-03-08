import 'package:inbota/modules/routines/data/models/routine_output.dart';

class RoutineSection {
  const RoutineSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<RoutineOutput> items;
}
