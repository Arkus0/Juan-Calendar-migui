import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../providers/settings_provider.dart';
import '../services/whatsapp_service.dart';
import '../widgets/contact_card.dart';
import 'contact_form_screen.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);
    final dossierTemplate = ref.watch(dossierTemplateProvider);
    final whatsappService = WhatsAppService();

    void sendDossier(String name, String phone) async {
      final message = dossierTemplate.replaceAll('[Nombre]', name);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await whatsappService.sendDossier(phone: phone, message: message);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    return Scaffold(
      body: contacts.isEmpty
          ? const Center(child: Text("No tienes contactos guardados."))
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ContactCard(
                  contacto: contact,
                  onSendDossier: () => sendDossier(contact.nombre, contact.telefono),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'contacts_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactFormScreen()),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
