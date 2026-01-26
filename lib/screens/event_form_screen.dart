import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/evento.dart';
import '../providers/data_providers.dart';
import '../providers/settings_provider.dart';
import '../services/whatsapp_service.dart';
import 'contact_form_screen.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final Evento? evento;

  const EventFormScreen({Key? key, this.evento}) : super(key: key);

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _placeController;
  late TextEditingController _notesController;
  late String _type;
  late DateTime _startDate;
  late DateTime? _endDate;

  // For 'bolo' dossier integration
  String? _selectedContactId;

  @override
  void initState() {
    super.initState();
    final e = widget.evento;
    _titleController = TextEditingController(text: e?.titulo ?? '');
    _placeController = TextEditingController(text: e?.lugar ?? '');
    _notesController = TextEditingController(text: e?.notas ?? '');
    _type = e?.tipo ?? 'bolo';
    _startDate = e?.inicio ?? DateTime.now();
    _endDate = e?.fin;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStart) async {
    final initialDate = isStart ? _startDate : (_endDate ?? _startDate);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            _startDate = newDateTime;
            if (_endDate != null && _endDate!.isBefore(_startDate)) {
              _endDate = _startDate.add(const Duration(hours: 1));
            }
          } else {
            _endDate = newDateTime;
          }
        });
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final id = widget.evento?.id ?? const Uuid().v4();
      final newEvento = Evento(
        id: id,
        titulo: _titleController.text,
        tipo: _type,
        inicio: _startDate,
        fin: _endDate,
        lugar: _placeController.text.isEmpty ? null : _placeController.text,
        notas: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (widget.evento == null) {
        ref.read(eventsProvider.notifier).addEvento(newEvento);
      } else {
        ref.read(eventsProvider.notifier).updateEvento(newEvento);
      }
      Navigator.pop(context);
    }
  }

  void _sendDossier() async {
    if (_selectedContactId == null) return;

    final contacts = ref.read(contactsProvider);
    final contact = contacts.firstWhere((c) => c.id == _selectedContactId);
    final template = ref.read(dossierTemplateProvider);
    final message = template.replaceAll('[Nombre]', contact.nombre);

    try {
      await WhatsAppService().sendDossier(phone: contact.telefono, message: message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evento == null ? 'Nuevo Evento' : 'Editar Evento'),
        actions: [
          if (widget.evento != null)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Eliminar evento',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar evento'),
                    content: const Text(
                        '¿Estás seguro de que quieres eliminar este evento?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(eventsProvider.notifier)
                              .deleteEvento(widget.evento!.id);
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close screen
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
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
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: ['bolo', 'reunion', 'personal'].map((t) {
                return DropdownMenuItem(value: t, child: Text(t.toUpperCase()));
              }).toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Inicio: ${DateFormat('dd/MM/yyyy HH:mm').format(_startDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(true),
            ),
            ListTile(
              title: Text(_endDate == null
                  ? 'Fin: (Opcional)'
                  : 'Fin: ${DateFormat('dd/MM/yyyy HH:mm').format(_endDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(false),
            ),
            TextFormField(
              controller: _placeController,
              decoration: const InputDecoration(labelText: 'Lugar'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 3,
            ),

            // Sección Dossier si es 'bolo'
            if (_type == 'bolo') ...[
              const Divider(height: 32),
              const Text('Enviar Dossier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedContactId,
                      hint: const Text('Seleccionar Contacto'),
                      items: contacts.map((c) {
                        return DropdownMenuItem(value: c.id, child: Text(c.nombre));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedContactId = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactFormScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Enviar WhatsApp'),
                onPressed: _selectedContactId == null ? null : _sendDossier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
