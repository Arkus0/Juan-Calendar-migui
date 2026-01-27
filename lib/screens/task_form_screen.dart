import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/evento.dart';
import '../models/event_type.dart';
import '../providers/data_providers.dart';
import '../providers/app_providers.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Evento? tarea;
  final String? initialDescription;
  final bool initialNoDate;

  const TaskFormScreen({
    super.key,
    this.tarea,
    this.initialDescription,
    this.initialNoDate = false,
  });

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descController;
  late TextEditingController _catController;
  late TextEditingController _urgenciaController;
  late TextEditingController _tagsController;
  late TextEditingController _lugarController;
  late TextEditingController _contactosController;
  late DateTime _date;
  late bool _noDate;
  final List<String> _subtareas = [];
  final _subtareaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.tarea?.titulo ?? widget.initialDescription ?? '');
    _catController = TextEditingController(text: widget.tarea?.categoria ?? '');
    _urgenciaController = TextEditingController(text: widget.tarea?.notas ?? '');
    _tagsController = TextEditingController(text: widget.tarea?.reminders != null && widget.tarea!.reminders.isNotEmpty ? widget.tarea!.reminders.join(', ') : '');
    _lugarController = TextEditingController(text: widget.tarea?.lugar ?? '');
    _contactosController = TextEditingController(
      text: widget.tarea?.contactos?.join(', ') ?? '',
    );
    // Default to selected date from provider if new task, or today
    if (widget.tarea != null) {
      _date = widget.tarea!.inicio;
      _noDate = !widget.tarea!.hasDate;
      // Cargar subtareas si existen
      if (widget.tarea!.parentId == null && widget.tarea!.id.isNotEmpty) {
        // Buscar subtareas asociadas a esta tarea principal
        final tareas = ref.read(tasksProvider);
        final subtareas = tareas.where((t) => t.parentId == widget.tarea!.id).toList();
        _subtareas.clear();
        _subtareas.addAll(subtareas.map((s) => s.titulo));
      }
    } else {
      _date = ref.read(selectedDateProvider);
      _noDate = widget.initialNoDate;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _catController.dispose();
    _urgenciaController.dispose();
    _tagsController.dispose();
    _lugarController.dispose();
    _contactosController.dispose();
    _subtareaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;
    if (picked != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );
      if (!mounted) return;
      if (pickedTime != null) {
        setState(() => _date = DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute));
      } else {
        setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final id = widget.tarea?.id ?? const Uuid().v4();
      final contactosList = _contactosController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final newTarea = Evento(
        id: id,
        titulo: _descController.text,
        tipo: EventType.personal,
        inicio: _date,
        categoria: _catController.text.isEmpty ? null : _catController.text,
        isTask: true,
        completada: widget.tarea?.completada ?? false,
        hasDate: !_noDate,
        contactos: contactosList.isNotEmpty ? contactosList : null,
        notas: _urgenciaController.text.isNotEmpty ? _urgenciaController.text : null,
        reminders: _tagsController.text.isNotEmpty ? _tagsController.text.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList() : [],
      );

      if (widget.tarea == null) {
        ref.read(tasksProvider.notifier).addTarea(newTarea);
      } else {
        ref.read(tasksProvider.notifier).updateTarea(newTarea);
      }
      // Eliminar subtareas antiguas del padre para evitar duplicados
      if (widget.tarea != null) {
        final tareas = ref.read(tasksProvider);
        final subtareasAntiguas = tareas.where((t) => t.parentId == id).toList();
        for (final st in subtareasAntiguas) {
          ref.read(tasksProvider.notifier).deleteTarea(st.id);
        }
      }
      // Guardar solo subtareas nuevas (no vacías)
      for (final subt in _subtareas.where((s) => s.trim().isNotEmpty)) {
        final subId = const Uuid().v4();
        final subTarea = Evento(
          id: subId,
          titulo: subt,
          tipo: EventType.personal,
          inicio: _date,
          isTask: true,
          completada: false,
          hasDate: !_noDate,
          parentId: id,
        );
        ref.read(tasksProvider.notifier).addTarea(subTarea);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tarea == null ? 'Nueva Tarea' : 'Editar Tarea'),
        actions: [
          if (widget.tarea != null)
             IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref.read(tasksProvider.notifier).deleteTarea(widget.tarea!.id);
                Navigator.pop(context);
              },
            ),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _catController,
              decoration: const InputDecoration(labelText: 'Categoría (Opcional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urgenciaController,
              decoration: const InputDecoration(labelText: 'Urgencia (Opcional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(labelText: 'Tags (separados por coma)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lugarController,
              decoration: const InputDecoration(labelText: 'Lugar (Opcional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactosController,
              decoration: const InputDecoration(labelText: 'Contactos (IDs o nombres, separados por coma)'),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Tarea sin fecha (Backlog)'),
              value: _noDate,
              onChanged: (v) => setState(() => _noDate = v ?? false),
            ),
            if (!_noDate)
              ListTile(
                title: Text('Fecha máxima: ${DateFormat('dd/MM/yyyy HH:mm').format(_date)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
            const SizedBox(height: 16),
            Text('Subtareas', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subtareaController,
                    decoration: const InputDecoration(hintText: 'Nueva subtarea'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_subtareaController.text.trim().isNotEmpty) {
                      setState(() {
                        _subtareas.add(_subtareaController.text.trim());
                        _subtareaController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            ..._subtareas.map((s) => ListTile(
                  title: Text(s),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _subtareas.remove(s);
                      });
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
