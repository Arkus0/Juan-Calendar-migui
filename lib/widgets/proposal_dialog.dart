import 'package:flutter/material.dart';
import '../screens/event_form_screen.dart';
import '../screens/task_form_screen.dart';

class ProposalDialog extends StatefulWidget {
  final String text;

  const ProposalDialog({Key? key, required this.text}) : super(key: key);

  @override
  _ProposalDialogState createState() => _ProposalDialogState();
}

class _ProposalDialogState extends State<ProposalDialog> {
  late TextEditingController _textController;
  String _selectedType = 'tarea'; // tarea, bolo, reunion, personal

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.text);
    _analyzeText();
  }

  void _analyzeText() {
    final lower = widget.text.toLowerCase();
    if (lower.contains('bolo') || lower.contains('concierto') || lower.contains('actuación') || lower.contains('sala')) {
      _selectedType = 'bolo';
    } else if (lower.contains('reunión') || lower.contains('cita')) {
      _selectedType = 'reunion';
    } else if (lower.contains('personal') || lower.contains('cena') || lower.contains('comida')) {
      _selectedType = 'personal';
    } else {
      _selectedType = 'tarea';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Texto Detectado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Texto...',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Crear como:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'tarea', child: Text('Tarea / Nota')),
                DropdownMenuItem(value: 'bolo', child: Text('Evento: Bolo')),
                DropdownMenuItem(value: 'reunion', child: Text('Evento: Reunión')),
                DropdownMenuItem(value: 'personal', child: Text('Evento: Personal')),
              ],
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _navigateToForm();
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  void _navigateToForm() {
    if (_selectedType == 'tarea') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskFormScreen(
            initialDescription: _textController.text,
          ),
        ),
      );
    } else {
      // Evento
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventFormScreen(
            initialTitle: _textController.text,
            initialType: _selectedType,
          ),
        ),
      );
    }
  }
}
