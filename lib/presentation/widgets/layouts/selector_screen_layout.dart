import 'package:anuncia_mi_llegada/presentation/widgets/shared/shared_buttons/custom_button.dart';
import 'package:anuncia_mi_llegada/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../icons/map_icon.dart';
import '../shared/shared_buttons/history_button.dart';
import '../shared/shared_buttons/settings_button.dart';

class SelectorScreenLayout extends StatelessWidget {
  final Widget selector;
  final bool showReturnButton;
  final VoidCallback? onReturnTap;

  //Separación entre el borde superior de la pantalla y el ícono del mapa
  static const double _topSpacing = 25;
  //Separación mínima entre el selector y el ícono del mapa / el botón de retroceder
  static const double _selectorSpacing = 16;
  //Separación simétrica del botón de retroceder: 40px arriba y 40px abajo
  static const double _returnButtonSpacing = 40;
  //Separación mínima entre el botón de ajustes y el borde inferior de la
  //pantalla. El espacio de abajo sigue siendo elástico: crece con el espacio
  //que sobra en la pantalla (como el Spacer del layout anterior).
  static const double _settingsButtonSpacing = 30;
  //Alto de diseño del selector (contenedor naranja). Nunca se excede.
  static const double _designSelectorHeight = 386;

  const SelectorScreenLayout({
    super.key,
    required this.selector,
    this.showReturnButton = true,
    this.onReturnTap,
  });

  @override
  Widget build(BuildContext context) {
    //Widgets que se miden para conocer la altura real de los bloques fijos
    //antes de decidir cuánto espacio le corresponde al selector. El footer no
    //contiene ningún LayoutBuilder, así que su altura intrínseca es exacta
    //(independiente de la fuente que use el botón de retroceder).
    final Widget headerBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: _topSpacing),
        Stack(
          children: [
            //MapIcon
            const Center(child: MapIcon()),
            //-------

            //History Button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 38, top: 16),
                child: HistoryButton(),
              ),
            ),
            //--------------
          ],
        ),
      ],
    );

    final Widget footerBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //Return Button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: _returnButtonSpacing),
          child: IgnorePointer(
            ignoring: !showReturnButton,
            child: AnimatedOpacity(
              opacity: showReturnButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: CustomButton(
                buttonAction: () {
                  if (onReturnTap != null) {
                    onReturnTap!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                textOfButton: Text(
                  'Retroceder',
                  style: AppTheme.nunitoFamilyCustomButton.copyWith(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ),
        //--------------

        //Settings Button
        Padding(
          padding: const EdgeInsets.only(bottom: _settingsButtonSpacing),
          child: const SettingsButton(),
        ),
        //---------------
      ],
    );

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          //Altura de los bloques fijos de la pantalla, en unidades de diseño:
          //  header = separación superior + alto del ícono del mapa (95px)
          //  footer = separación del botón de retroceder (40px arriba y abajo)
          //           + botón de retroceder (42px: Nunito 17px + padding 20)
          //           + botón de ajustes (48px) + separación inferior (30px)
          //El botón de retroceder mide 42px con la fuente del proyecto
          //(Nunito w700 17px, line-height 1.3 → 22px + 20px de padding
          //vertical). El selector nunca excede su tamaño de diseño y se encoge
          //en pantallas cortas, por lo que nunca desborda.
          const double headerHeight = _topSpacing + 95;
          const double returnButtonHeight = 42;
          const double settingsButtonHeight = 48;
          const double footerHeight =
              _returnButtonSpacing * 2 +
              returnButtonHeight +
              settingsButtonHeight +
              _settingsButtonSpacing;

          //Espacio que le corresponde al bloque del selector una vez
          //descontados los bloques fijos. Los 2 Spacer reparten 50/50 lo que
          //sobra, dejando el selector centrado entre el header y el footer y
          //devolviendo al settings button su espacio elástico inferior.
          final double selectorBlockHeight = (constraints.maxHeight -
                  headerHeight -
                  footerHeight)
              .clamp(0.0, _designSelectorHeight + _selectorSpacing * 2);

          return Column(
            children: [
              headerBlock,
              //----------

              //Primer Spacer (flex 1): reparte el sobrante 50/50 con el Spacer
              //inferior, dejando el selector centrado entre header y footer.
              const Spacer(flex: 1),
              //----------

              //Selector: altura acotada al espacio disponible (nunca excede su
              //tamaño de diseño de 386px más sus separaciones). Nunca desborda.
              SizedBox(
                height: selectorBlockHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: _selectorSpacing),
                  child: selector,
                ),
              ),
              //----------

              footerBlock,
              //----------

              //Segundo Spacer (flex 1): reparte el sobrante 50/50 con el
              //primer Spacer.
              const Spacer(flex: 1),
            ],
          );
        },
      ),
    );
  }
}
