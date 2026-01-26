import 'package:flutter/material.dart';

class RemindersSelector extends StatefulWidget {
  final List<int> initialReminders;
  final Function(List<int>) onChanged;

  const RemindersSelector({
    super.key,
    required this.initialReminders,
    required this.onChanged,
  });

  @override
  State<RemindersSelector> createState() => _RemindersSelectorState();
}

class _RemindersSelectorState extends State<RemindersSelector> {
  late List<int> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = List.from(widget.initialReminders);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.notifications_active),
          title: const Text('Recordatorios'),
          subtitle: Text(
            _reminders.isEmpty
                ? 'Sin recordatorios'
                : '${_reminders.length} recordatorio(s)',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _showAddReminderDialog,
          ),
        ),
        if (_reminders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _reminders.map((minutes) {
                return Chip(
                  label: Text(_formatReminder(minutes)),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      _reminders.remove(minutes);
                    });
                    widget.onChanged(_reminders);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _formatReminder(int minutes) {
    if (minutes < 60) {
      return '$minutes min antes';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return '$hours hora${hours > 1 ? 's' : ''} antes';
    } else {
      final days = minutes ~/ 1440;
      return '$days día${days > 1 ? 's' : ''} antes';
    }
  }

  Future<void> _showAddReminderDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => const _ReminderDialog(),
    );

    if (result != null && !_reminders.contains(result)) {
      setState(() {
        _reminders.add(result);
        _reminders.sort(); // Ordenar de menor a mayor
      });
      widget.onChanged(_reminders);
    }
  }
}

class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog();

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  int? _selectedPreset;
  int _customValue = 30;
  String _customUnit = 'minutes';

  final List<Map<String, dynamic>> _presets = [
    {'label': 'Al inicio del evento', 'minutes': 0},
    {'label': '5 minutos antes', 'minutes': 5},
    {'label': '15 minutos antes', 'minutes': 15},
    {'label': '30 minutos antes', 'minutes': 30},
    {'label': '1 hora antes', 'minutes': 60},
    {'label': '2 horas antes', 'minutes': 120},
    {'label': '1 día antes', 'minutes': 1440},
    {'label': '2 días antes', 'minutes': 2880},
    {'label': '1 semana antes', 'minutes': 10080},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir recordatorio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opciones rápidas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._presets.map((preset) {
              return RadioListTile<int>(
                title: Text(preset['label']),
                value: preset['minutes'],
                groupValue: _selectedPreset,
                onChanged: (value) {
                  setState(() {
                    _selectedPreset = value;
                  });
                },
              );
            }),
            const Divider(),
            const Text(
              'Personalizado:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Valor',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    controller: TextEditingController(text: _customValue.toString()),
                    onChanged: (value) {
                      _customValue = int.tryParse(value) ?? 30;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _customUnit,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'minutes', child: Text('Minutos')),
                      DropdownMenuItem(value: 'hours', child: Text('Horas')),
                      DropdownMenuItem(value: 'days', child: Text('Días')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _customUnit = value!;
                        _selectedPreset = null; // Deseleccionar preset
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            int minutes;
            if (_selectedPreset != null) {
              minutes = _selectedPreset!;
            } else {
              // Calcular minutos desde valor personalizado
              switch (_customUnit) {
                case 'minutes':
                  minutes = _customValue;
                  break;
                case 'hours':
                  minutes = _customValue * 60;
                  break;
                case 'days':
                  minutes = _customValue * 1440;
                  break;
                default:
                  minutes = _customValue;
              }
            }
            Navigator.pop(context, minutes);
          },
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}
