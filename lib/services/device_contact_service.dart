import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class DeviceContactService {
  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  Future<void> saveContact({
    required String firstName,
    required String phone,
  }) async {
    final bool granted = await requestPermission();
    if (!granted) {
      throw 'Permiso de contactos denegado';
    }

    final newContact = Contact()
      ..name.first = firstName
      ..phones = [Phone(phone)];

    try {
      await newContact.insert();
    } catch (e) {
      // Some devices/accounts can reject direct inserts (e.g., default cloud account).
      // Fallback: open the native contact insert UI so the user can save manually.
      debugPrint('Direct insert failed: $e — opening external insert UI as fallback');
      try {
        await FlutterContacts.openExternalInsert();
      } catch (e2) {
        throw 'Error al guardar en dispositivo: $e';
      }
    }
  }
}
