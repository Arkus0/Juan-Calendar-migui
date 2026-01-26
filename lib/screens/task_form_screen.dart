import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/tarea.dart';
import '../providers/data_providers.dart';
import '../providers/app_providers.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Tarea? tarea;
  final String? initialDescription;

  const TaskFormScreen({
    Key? key,
    this.tarea,
    this.initialDescription,
  }) : super(key: key);

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descController;
  late TextEditingController _catController;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.tarea?.descripcion ?? widget.initialDescription ?? '');
    _catController = TextEditingController(text: widget.tarea?.categoria ?? '');
    // Default to selected date from provider if new task, or today
    if (widget.tarea != null) {
      _date = widget.tarea!.fecha;
    } else {
      _date = ref.read(selectedDateProvider);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _catController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final id = widget.tarea?.id ?? const Uuid().v4();
      final newTarea = Tarea(
        id: id,
        descripcion: _descController.text,
        categoria: _catController.text.isEmpty ? null : _catController.text,
        fecha: _date,
        completada: widget.tarea?.completada ?? false,
      );

      if (widget.tarea == null) {
        ref.read(tasksProvider.notifier).addTarea(newTarea);
      } else {
        ref.read(tasksProvider.notifier).updateTarea(newTarea);
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
            ListTile(
              title: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_date)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
    );
  }
}
