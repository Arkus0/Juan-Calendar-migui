import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
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

    // Try to prefill the native contact insert UI on Android using intents.
    // Fallback to FlutterContacts.openExternalInsert() otherwise.
    try {
      if (Platform.isAndroid) {
        final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
        final intent = AndroidIntent(
          action: 'android.intent.action.INSERT',
          type: 'vnd.android.cursor.item/contact',
          arguments: {
            'name': firstName,
            'phone': cleanedPhone,
          },
        );
        await intent.launch();
      } else {
        await FlutterContacts.openExternalInsert();
      }
    } catch (e) {
      // Last resort: open external insert UI (no prefill)
      try {
        await FlutterContacts.openExternalInsert();
      } catch (e2) {
        throw 'Error al abrir la UI de inserción de contactos: $e2';
      }
    }
  }
}
