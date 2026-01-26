import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  Future<void> sendDossier({
    required String phone,
    required String message,
  }) async {
    // Clean phone number (remove spaces, etc, but keep +)
    // Assuming input is something like +34666555444 or 666555444
    String cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');

    // Encode message
    String encodedMessage = Uri.encodeComponent(message);

    // Create URL
    // Different schemes for Android/iOS might be needed sometimes, but usually https://wa.me works universally if the app is installed.
    // However, url_launcher recommends specific schemes.

    Uri url;
    if (Platform.isAndroid) {
       url = Uri.parse("https://wa.me/$cleanPhone?text=$encodedMessage");
    } else {
       // iOS usually handles wa.me too, or whatsapp://send
       url = Uri.parse("https://wa.me/$cleanPhone?text=$encodedMessage");
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir WhatsApp ($url)';
    }
  }
}
