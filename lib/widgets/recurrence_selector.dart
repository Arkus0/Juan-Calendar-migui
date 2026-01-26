import 'package:flutter/material.dart';
import '../models/recurrence_rule.dart';

class RecurrenceSelector extends StatefulWidget {
  final RecurrenceRule? initialRule;
  final Function(RecurrenceRule?) onChanged;

  const RecurrenceSelector({
    super.key,
    this.initialRule,
    required this.onChanged,
  });

  @override
  State<RecurrenceSelector> createState() => _RecurrenceSelectorState();
}

class _RecurrenceSelectorState extends State<RecurrenceSelector> {
  late RecurrenceRule? _rule;

  @override
  void initState() {
    super.initState();
    _rule = widget.initialRule;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.repeat),
          title: const Text('Repetir'),
          subtitle: Text(_rule?.getDisplayText() ?? 'No se repite'),
          trailing: const Icon(Icons.edit),
          onTap: _showRecurrenceDialog,
        ),
        if (_rule != null && _rule!.type != RecurrenceType.none)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Chip(
              label: Text(_rule!.getDisplayText()),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _rule = null;
                });
                widget.onChanged(null);
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showRecurrenceDialog() async {
    final result = await showDialog<RecurrenceRule?>(
      context: context,
      builder: (context) => _RecurrenceDialog(initialRule: _rule),
    );

    if (result != null) {
      setState(() {
        _rule = result;
      });
      widget.onChanged(result);
    }
  }
}

class _RecurrenceDialog extends StatefulWidget {
  final RecurrenceRule? initialRule;

  const _RecurrenceDialog({this.initialRule});

  @override
  State<_RecurrenceDialog> createState() => _RecurrenceDialogState();
}

class _RecurrenceDialogState extends State<_RecurrenceDialog> {
  late RecurrenceType _type;
  late int _interval;
  late int? _count;

  @override
  void initState() {
    super.initState();
    _type = widget.initialRule?.type ?? RecurrenceType.none;
    _interval = widget.initialRule?.interval ?? 1;
    _count = widget.initialRule?.count ?? 12;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar repetición'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Frecuencia:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            if (_type != RecurrenceType.none) ...[
              const SizedBox(height: 16),
              _buildIntervalSelector(),
              const SizedBox(height: 16),
              _buildCountSelector(),
            ],
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
            final rule = _type == RecurrenceType.none
                ? null
                : RecurrenceRule(
                    type: _type,
                    interval: _interval,
                    count: _count,
                  );
            Navigator.pop(context, rule);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<RecurrenceType>(
      segments: const [
        ButtonSegment(
          value: RecurrenceType.none,
          label: Text('Nunca'),
        ),
        ButtonSegment(
          value: RecurrenceType.daily,
          label: Text('Diario'),
        ),
        ButtonSegment(
          value: RecurrenceType.weekly,
          label: Text('Semanal'),
        ),
        ButtonSegment(
          value: RecurrenceType.monthly,
          label: Text('Mensual'),
        ),
      ],
      selected: {_type},
      onSelectionChanged: (Set<RecurrenceType> selected) {
        setState(() {
          _type = selected.first;
        });
      },
    );
  }

  Widget _buildIntervalSelector() {
    String label;
    switch (_type) {
      case RecurrenceType.daily:
        label = 'Cada cuántos días';
        break;
      case RecurrenceType.weekly:
        label = 'Cada cuántas semanas';
        break;
      case RecurrenceType.monthly:
        label = 'Cada cuántos meses';
        break;
      default:
        label = 'Intervalo';
    }

    return Row(
      children: [
        Expanded(
          child: Text(label),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 80,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            controller: TextEditingController(text: _interval.toString()),
            onChanged: (value) {
              _interval = int.tryParse(value) ?? 1;
              if (_interval < 1) _interval = 1;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountSelector() {
    return Row(
      children: [
        const Expanded(
          child: Text('Número de repeticiones'),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 80,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            controller: TextEditingController(text: _count?.toString() ?? '12'),
            onChanged: (value) {
              _count = int.tryParse(value);
            },
          ),
        ),
      ],
    );
  }
}
