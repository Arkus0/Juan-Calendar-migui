import 'tarea.dart';

sealed class AgendaItem {}

class AgendaHeader extends AgendaItem {
  final String text;
  AgendaHeader(this.text);
}

class AgendaTaskItem extends AgendaItem {
  final Tarea task;
  AgendaTaskItem(this.task);
}

class AgendaEmptyItem extends AgendaItem {
  final String text;
  AgendaEmptyItem(this.text);
}
