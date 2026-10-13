import 'dart:async';
import 'package:anuncia_mi_llegada/config/preferences/preferences_service.dart';
import 'package:anuncia_mi_llegada/data/models/history_items.dart';
import 'package:anuncia_mi_llegada/presentation/widgets/layouts/history_screen_layout.dart';
import 'package:anuncia_mi_llegada/theme/app_theme.dart';
import 'package:anuncia_mi_llegada/utils/platform_dialog_helper.dart';
import 'package:anuncia_mi_llegada/utils/send_message_helper.dart';
import 'package:flutter/material.dart';


class HistoryScreen extends StatefulWidget {
  static const name = 'history_screen';

  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectCategory = 'TODOS';

  final List<String> categories = [
    'TODOS',
    'LÍNEAS',
    'CABLEBÚS',
    'METRO',
    'METROBÚS',
    'MEXIBÚS',
    'MEXICABLE',
    'TREN LIGERO',
    'TRENES V.M',
    'TROLEBÚS',
    'UBI.PERSONALIZADA',
  ];

  Future<void> _resendMessage(HistoryItems record) async {
    final messageBody = PreferencesService.messageBody.value;
    final mensajeFinal = '$messageBody ${record.stationName}';

    final result = await SendMessageHelper.sendMessage(mensajeFinal);

    if (result == SendMessageResult.whatsappUnavailable ||
        result == SendMessageResult.failed) {
      if (mounted) {
        await SendMessageHelper().showSendMessageError(context, result);
      }
      return;
    }

    //Al reenviar se registra una nueva entrada con fecha/hora actual.
    final newHistoryItem = HistoryItems(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      stationName: record.stationName,
      transportAndLineName: record.transportAndLineName,
      category: record.category,
      messageTime: DateTime.now(),
    );
    await PreferencesService.saveToHistoryItems(newHistoryItem);
  }

    Future<bool> _confirmDelete(BuildContext context, HistoryItems item) async {
    final completer = Completer<bool>();
    showPlatformDialog(
      context: context,
      title: '¿Eliminar este elemento?',
      content: 'Se eliminará "${item.stationName}" del historial.',
      actions: [
        PlatformDialogAction(
          text: 'Rechazar',
          onPressed: () => completer.complete(false),
        ),
        PlatformDialogAction(
          text: 'Continuar',
          isDestructive: true,
          onPressed: () => completer.complete(true),
        ),
      ],
    );
    //Respaldo por si el diálogo se cierra tocando el fondo.
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Implementación del backgroundColor
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<bool>(
        valueListenable: isTrueDarkMode,
        builder: (context, isDark, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isDark ? null : AppTheme.backgroundColorLM,
            gradient: isDark ? AppTheme.backgroundColorDM : null,
          ),
          //-------------------------------------
          child: HistoryScreenLayout(
            historyWidget: Column(
              children: [
                ValueListenableBuilder<List<HistoryItems>>(
                  valueListenable: PreferencesService.historyList,
                  builder: (context, historyItems, _) => SizedBox(
                    height: 30,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('|', style: AppTheme.metroStyle),
                      ),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category == selectCategory;
                        final label = category == 'TODOS'
                            ? 'TODOS (${historyItems.length})'
                            : category;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectCategory = category),
                          child: Center(
                            child: Text(
                              label,
                              style: isSelected
                                  ? AppTheme.metroStyle
                                  : AppTheme.metroStyle.copyWith(
                                      color: AppTheme.metroStyle.color
                                          ?.withValues(alpha: 0.66),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: Color(0xFFF69346),
                  thickness: 1,
                  height: 8,
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 10),
                //Historial
                Expanded(
                  child: ValueListenableBuilder<List<HistoryItems>>(
                    valueListenable: PreferencesService.historyList,
                    builder: (context, historyItems, _) {
                      final filteredList = selectCategory == 'TODOS'
                          ? historyItems
                          : historyItems
                                .where(
                                  (item) => item.category == selectCategory,
                                )
                                .toList();

                      if (filteredList.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aún no has anunciado tu llegada',
                            style: AppTheme.nunitoFamilySubtitle,
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final history = filteredList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Dismissible(
                              key: ValueKey(history.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD32F2F),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (_) =>
                                  _confirmDelete(context, history),
                              onDismissed: (_) =>
                                  PreferencesService.deleteHistoryItem(
                                    history.id,
                                  ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _resendMessage(history),
                                  onLongPress: () async {
                                    final confirm =
                                        await _confirmDelete(
                                          context,
                                          history,
                                        );
                                    if (confirm) {
                                      await PreferencesService
                                          .deleteHistoryItem(history.id);
                                    }
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 12.0),
                                        child: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: Color(0xFFF69346),
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              history.stationName[0]
                                                      .toUpperCase() +
                                                  history.stationName
                                                      .substring(1),
                                              style: AppTheme.nunitoFamily,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              history.transportAndLineName,
                                              style:
                                                  AppTheme.nunitoFamilySubtitle,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
