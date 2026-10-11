import 'package:anuncia_mi_llegada/presentation/widgets/shared/shared_buttons/history_button.dart';
import 'package:anuncia_mi_llegada/presentation/widgets/shared/shared_buttons/keyboard_return_button.dart';
import 'package:flutter/material.dart';
import '../icons/map_icon.dart';
import '../shared/shared_buttons/settings_button.dart';

class CustomLocationScreenLayout extends StatelessWidget {
  final Widget keyboardReturnButton;
  final Widget customLocationOptions;

  const CustomLocationScreenLayout({
    super.key,
    required this.customLocationOptions,
    this.keyboardReturnButton = const KeyboardReturnButton(),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          //Disposición del MapIcon, Keyboard Return Button y History Button
          children: [
            Column(
              children: [
                const SizedBox(height: 25),
                Stack(
                  children: [
                    //MapIcon
                    const Center(child: MapIcon()),
                    //-------

                    //Keyboard Return Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 28, top: 13),
                        child: KeyboardReturnButton(),
                      ),
                    ),
                    //-----------------------

                    //History Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 38, top: 13),
                        child: HistoryButton(),
                      ),
                    ),

                    //--------------
                  ],
                ),
                //---------------------------------------

                Flexible(
                  flex: 14,
                  child: SizedBox(
                    width: 540,
                    height: 520,
                    child: customLocationOptions,
                  ),
                ),

                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const SettingsButton()],
                ),
                const Spacer(),
              ],
            ),

            //----------------------------------------------
          ],
        ),
      ),
    );
  }
}
