import 'package:anuncia_mi_llegada/config/preferences/preferences_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anuncia_mi_llegada/utils/platform_dialog_helper.dart';
import 'package:flutter/material.dart';

enum SendMessageResult { succes, whatsappUnavailable, failed }

class SendMessageHelper {
  static Future<SendMessageResult> sendMessage(String mensajeFinal) async {
    final preferredApp = PreferencesService.whatMessagingAppYouWillUse.value;

    if (preferredApp == PreferencesService.messagingAppWhatsApp) {
      final Uri whatsappUri = Uri.parse(
        "whatsapp://send?text=${Uri.encodeComponent(mensajeFinal)}"
      );
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
        return SendMessageResult.succes;
      }
      return SendMessageResult.whatsappUnavailable;
    }

    if (preferredApp == PreferencesService.messagingAppAny) {
      final ShareResult result = await SharePlus.instance.share(ShareParams(text: mensajeFinal));
      return result.status == ShareResultStatus.success
        ? SendMessageResult.succes
        : SendMessageResult.failed;
      }

      final Uri smsUri = Uri.parse(
        'sms:?body=${Uri.encodeComponent(mensajeFinal)}',
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return SendMessageResult.succes;
      }
      return SendMessageResult.failed;
    }

    Future<void> showSendMessageError(
      BuildContext context,
      SendMessageResult result,
    ) async {
      if (result == SendMessageResult.whatsappUnavailable){
        await showPlatformDialog(
          context: context, 
          title: "No se pudo abrir WhatsApp", 
          content: "WhatsApp no esta instalada o no se pudo abrir. Puedes ir a Configuración → Mensajes , y elegir otra app para el envío del mensaje, o verifica que WhatsApp este disponible. ", 
          actions: [
            PlatformDialogAction(text: 'Aceptar'),
          ],
        );
      }
    }
  }
