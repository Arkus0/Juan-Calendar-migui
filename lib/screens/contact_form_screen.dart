import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/contacto.dart';
import '../providers/data_providers.dart';
import '../services/device_contact_service.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  final Contacto? contacto;

  const ContactFormScreen({Key? key, this.contacto}) : super(key: key);

  @override
  _ContactFormScreenState createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _saveToDevice = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contacto?.nombre ?? '');
    _phoneController = TextEditingController(text: widget.contacto?.telefono ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_saveToDevice) {
        try {
          await DeviceContactService().saveContact(
            firstName: _nameController.text,
            phone: _phoneController.text,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en el dispositivo')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar en dispositivo: $e')));
          }
          // Continue saving in app
        }
      }

      final id = widget.contacto?.id ?? const Uuid().v4();
      final newContact = Contacto(
        id: id,
        nombre: _nameController.text,
        telefono: _phoneController.text,
      );

      if (widget.contacto == null) {
        ref.read(contactsProvider.notifier).addContacto(newContact);
      } else {
        ref.read(contactsProvider.notifier).updateContacto(newContact);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contacto == null ? 'Nuevo Contacto' : 'Editar Contacto'),
        actions: [
           IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 20),
            if (widget.contacto == null) // Only show option for new contacts
              SwitchListTile(
                title: const Text('Guardar también en agenda del móvil'),
                value: _saveToDevice,
                onChanged: (v) => setState(() => _saveToDevice = v),
              ),
          ],
        ),
      ),
    );
  }
}
