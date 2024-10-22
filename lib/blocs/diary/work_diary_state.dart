import 'package:equatable/equatable.dart';
import 'package:build_wise/models/work_diary_entry.dart';

abstract class WorkDiaryState extends Equatable {
  @override
  List<Object> get props => [];
}

class WorkDiaryLoading extends WorkDiaryState {}

class WorkDiaryLoaded extends WorkDiaryState {
  final List<WorkDiaryEntry> entries;

  WorkDiaryLoaded(this.entries);

  @override
  List<Object> get props => [entries];
}

class WorkDiaryEmpty extends WorkDiaryState {}

class WorkDiaryError extends WorkDiaryState {
  final String message;

  WorkDiaryError(this.message);

  @override
  List<Object> get props => [message];
}
