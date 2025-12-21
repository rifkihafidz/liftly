import 'package:equatable/equatable.dart';

class CustomExercise extends Equatable {
  final String name;
  final List<String> variants;

  const CustomExercise({
    required this.name,
    this.variants = const [],
  });

  @override
  List<Object?> get props => [name, variants];
}
