import 'package:equatable/equatable.dart';
import 'package:build_wise/models/work_diary_entry.dart';

abstract class WorkDiaryEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadWorkDiaryEntriesEvent extends WorkDiaryEvent {
  final String userId;
  final String projectId;

  LoadWorkDiaryEntriesEvent(this.userId, this.projectId);

  @override
  List<Object> get props => [userId, projectId];
}

class AddWorkDiaryEntryEvent extends WorkDiaryEvent {
  final String userId;
  final String projectId;
  final WorkDiaryEntry entry;

  AddWorkDiaryEntryEvent(this.userId, this.projectId, this.entry);

  @override
  List<Object> get props => [userId, projectId, entry];
}

class EditWorkDiaryEntryEvent extends WorkDiaryEvent {
  final String userId;
  final String projectId;
  final String entryId;
  final WorkDiaryEntry updatedEntry;

  EditWorkDiaryEntryEvent(
      this.userId, this.projectId, this.entryId, this.updatedEntry);

  @override
  List<Object> get props => [userId, projectId, entryId, updatedEntry];
}

class DeleteWorkDiaryEntryEvent extends WorkDiaryEvent {
  final String userId;
  final String projectId;
  final String entryId;

  DeleteWorkDiaryEntryEvent(this.userId, this.projectId, this.entryId);

  @override
  List<Object> get props => [userId, projectId, entryId];
}

class UpdateWorkDiaryEntryEvent extends WorkDiaryEvent {
  final String userId;
  final String projectId;
  final WorkDiaryEntry entry;

  UpdateWorkDiaryEntryEvent(this.userId, this.projectId, this.entry);

  @override
  List<Object> get props => [userId, projectId, entry];
}
