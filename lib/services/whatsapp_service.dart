import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';


class WhatsAppService {
  /// If [pdfPath] is provided we share the file (Share.shareFiles) so the user can
  /// choose WhatsApp with the PDF attached. Otherwise try to open WhatsApp directly
  /// with the text message via URI schemes.
  Future<void> sendDossier({
    required String phone,
    required String message,
    List<String>? pdfPaths,
  }) async {
    // If PDF paths provided, try to share them
    if (pdfPaths != null && pdfPaths.isNotEmpty) {
      try {
        final xfiles = pdfPaths.where((p) => p.isNotEmpty).map((p) => XFile(p)).toList();
        if (xfiles.isNotEmpty) {
          await SharePlus.instance.share(ShareParams(text: message, files: xfiles));
          return;
        }
      } catch (e) {
        // fallback to text-only behavior
      }
    }

    // Clean phone number (remove spaces, etc, but keep +)
    String cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');

    // Encode message
    String encodedMessage = Uri.encodeComponent(message);

    // Try whatsapp custom scheme first (works if WhatsApp is installed), fallback to wa.me
    final phoneForIntent = cleanPhone.replaceAll('+', '');
    final uriWhatsappScheme = Uri.parse('whatsapp://send?phone=$phoneForIntent&text=$encodedMessage');
    final uriWaMe = Uri.parse('https://wa.me/$phoneForIntent?text=$encodedMessage');

    if (await canLaunchUrl(uriWhatsappScheme)) {
      await launchUrl(uriWhatsappScheme, mode: LaunchMode.externalApplication);
      return;
    }

    if (await canLaunchUrl(uriWaMe)) {
      await launchUrl(uriWaMe, mode: LaunchMode.externalApplication);
      return;
    }

    // Last resort: share text via system share sheet
    try {
      await SharePlus.instance.share(ShareParams(text: message));
      return;
    } catch (e) {
      throw 'No se pudo abrir WhatsApp ni compartir (tried $uriWhatsappScheme, $uriWaMe)';
    }
  }
}
