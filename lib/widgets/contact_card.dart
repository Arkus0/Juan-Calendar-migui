import 'package:flutter/material.dart';
import '../models/contacto.dart';

class ContactCard extends StatelessWidget {
  final Contacto contacto;
  final VoidCallback onSendDossier;

  const ContactCard({
    super.key,
    required this.contacto,
    required this.onSendDossier,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(contacto.nombre),
        subtitle: Text(contacto.telefono),
        trailing: IconButton(
          icon: const Icon(Icons.send_to_mobile, color: Colors.green),
          tooltip: 'Enviar Dossier',
          onPressed: onSendDossier,
        ),
      ),
    );
  }
}
