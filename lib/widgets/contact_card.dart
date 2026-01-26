import 'package:flutter/material.dart';
import '../models/contacto.dart';

class ContactCard extends StatelessWidget {
  final Contacto contacto;
  final VoidCallback onSendDossier;

  const ContactCard({
    Key? key,
    required this.contacto,
    required this.onSendDossier,
  }) : super(key: key);

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
