import 'package:anuncia_mi_llegada/presentation/widgets/icons/history_icon.dart';
import 'package:anuncia_mi_llegada/presentation/widgets/shared/shared_buttons/keyboard_return_button.dart';
import 'package:anuncia_mi_llegada/presentation/widgets/shared/shared_buttons/settings_button.dart';
import 'package:flutter/material.dart';

class HistoryScreenLayout extends StatelessWidget {
  
  final Widget historyWidget; 
  
  const HistoryScreenLayout({
    required this.historyWidget,
    super.key, 
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const SizedBox(height: 25),
          Stack(
            children: [
              //RecordIcon
              const Center(child: HistoryIcon()),
              //------------
              //KeyoboardReturnButton
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 28, top: 8),
                  child: KeyboardReturnButton(),
                ),
              ),
              //---------------------
              Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 28, top: 8),
                child: SettingsButton(),
              ),
            ),
            ],
          ),
          SizedBox(height: 20,),
          Expanded(child: historyWidget),
        ],
      ),
    );
  }
}