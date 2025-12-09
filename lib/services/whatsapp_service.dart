import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  WhatsAppService._();

  static Future<void> openWhatsApp(String phoneNumber, {String? message}) async {
    var trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Phone number is empty');
    }
    // Auto-prefix +91 for local numbers that don't include country code
    if (!trimmed.startsWith('+')) {
      trimmed = '+91$trimmed';
    }
    final text = Uri.encodeComponent(message ?? '');

    // Try native whatsapp:// scheme first
    final whatsappUri = Uri.parse('whatsapp://send?phone=$trimmed&text=$text');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback to HTTPS wa.me link
    final webUri = Uri.parse('https://wa.me/$trimmed?text=$text');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }

    throw 'Could not launch WhatsApp';
  }
}
