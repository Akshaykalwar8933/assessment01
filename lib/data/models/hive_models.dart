import 'package:hive_ce/hive.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/team_member.dart';

abstract final class HiveTypeIds {
  static const int task = 0;
  static const int teamMember = 1;
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.assigneeId,
    required this.createdAtMs,
    this.description,
    this.dueAtMs,
    required this.status,
    this.completedAtMs,
  });

  factory TaskModel.fromEntity(Task t) => TaskModel(
    id: t.id,
    title: t.title,
    assigneeId: t.assigneeId,
    createdAtMs: t.createdAt.millisecondsSinceEpoch,
    description: t.description,
    dueAtMs: t.dueAt?.millisecondsSinceEpoch,
    status: t.status.name,
    completedAtMs: t.completedAt?.millisecondsSinceEpoch,
  );

  final String id;
  final String title;
  final String assigneeId;
  final int createdAtMs;
  final String? description;
  final int? dueAtMs;
  final String status;
  final int? completedAtMs;

  Task toEntity() {
    final closed = status == TaskStatus.closed.name && completedAtMs != null;
    return Task(
      id: id,
      title: title,
      assigneeId: assigneeId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      description: description,
      dueAt: dueAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dueAtMs!),
      status: closed ? TaskStatus.closed : TaskStatus.open,
      completedAt: closed
          ? DateTime.fromMillisecondsSinceEpoch(completedAtMs!)
          : null,
    );
  }
}

class TeamMemberModel {
  const TeamMemberModel({required this.id, required this.name, this.avatarUrl});

  factory TeamMemberModel.fromEntity(TeamMember m) =>
      TeamMemberModel(id: m.id, name: m.name, avatarUrl: m.avatarUrl);

  final String id;
  final String name;
  final String? avatarUrl;

  TeamMember toEntity() => TeamMember(id: id, name: name, avatarUrl: avatarUrl);
}

Map<int, dynamic> _readFields(BinaryReader reader) {
  final count = reader.readByte();
  return {for (var i = 0; i < count; i++) reader.readByte(): reader.read()};
}

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = HiveTypeIds.task;

  @override
  TaskModel read(BinaryReader reader) {
    final f = _readFields(reader);
    return TaskModel(
      id: f[0] as String,
      title: f[1] as String,
      assigneeId: f[2] as String,
      createdAtMs: f[3] as int,
      dueAtMs: f[4] as int?,
      status: f[5] as String,
      completedAtMs: f[6] as int?,
      // Added after v1; absent in older records.
      description: f[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.assigneeId)
      ..writeByte(3)
      ..write(obj.createdAtMs)
      ..writeByte(4)
      ..write(obj.dueAtMs)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.completedAtMs)
      ..writeByte(7)
      ..write(obj.description);
  }
}

class TeamMemberModelAdapter extends TypeAdapter<TeamMemberModel> {
  @override
  final int typeId = HiveTypeIds.teamMember;

  @override
  TeamMemberModel read(BinaryReader reader) {
    final f = _readFields(reader);
    return TeamMemberModel(
      id: f[0] as String,
      name: f[1] as String,
      avatarUrl: f[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TeamMemberModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatarUrl);
  }
}
