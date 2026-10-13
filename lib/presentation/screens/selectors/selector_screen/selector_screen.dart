import 'package:anuncia_mi_llegada/config/preferences/preferences_service.dart';
import 'package:anuncia_mi_llegada/data/models/mi_model.dart';
import 'package:anuncia_mi_llegada/data/models/history_items.dart';
import 'package:anuncia_mi_llegada/data/repositories/mi_repository.dart';
import 'package:anuncia_mi_llegada/presentation/screens/screens.dart';
import 'package:anuncia_mi_llegada/presentation/widgets/layouts/selector_screen_layout.dart';
import 'package:anuncia_mi_llegada/presentation/widgets/selector/selector_widget.dart';
import 'package:anuncia_mi_llegada/theme/app_theme.dart';
import 'package:anuncia_mi_llegada/utils/send_message_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _SelectorStep { transports, lines, stations }

class _StaggeredFadeIn extends StatefulWidget {
  const _StaggeredFadeIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final start = (widget.index * 0.08).clamp(0.0, 0.6);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

//Mapea del nombre del transporte con su categoría exacta
String _transportCategory(String transportName) {
  const categories = <String, String>{
    'Metro': 'METRO',
    'Metrobús': 'METROBÚS',
    'Trolebús': 'TROLEBÚS',
    'Cablebús': 'CABLEBÚS',
    'Mexibús': 'MEXÍBUS',
    'Mexicable': 'MEXICABLE',
    'Tren Ligero': 'TREN LIGERO',
    'Trenes del Valle de México': 'TRENES V.M',
  };
  return categories[transportName] ?? 'UBI.PERSONALIZADA';
}
//------------

class SelectorScreen extends StatefulWidget {
  const SelectorScreen({super.key});

  static const name = 'selector_screen';

  @override
  State<SelectorScreen> createState() => _SelectorScreenState();
}

//Estilo de texto: nunitoFamily
final _nunitoFamily = TextStyle(
  color: Colors.white,
  height: 1,
  fontFamily: 'Nunito',
  fontSize: 17,
  letterSpacing: 0,
  fontWeight: FontWeight.w700,
);

class _SelectorScreenState extends State<SelectorScreen> {
  late Future<List<TransportsModel>> _transportsFuture;

  _SelectorStep _step = _SelectorStep.transports;
  TransportsModel? _transport;
  LinesModel? _line;

  @override
  void initState() {
    super.initState();
    _loadTransports();
    PreferencesService.willBeShowedLineNamesInMessage.addListener(
      _loadTransports,
    );
    PreferencesService.willBeShowedInstitutionsName.addListener(
      _loadTransports,
    );
  }

  void _loadTransports() {
    setState(() {
      _step = _SelectorStep.transports;
      _transport = null;
      _line = null;
      _transportsFuture = MiRepository().loadTransports(
        showLineNamesInMessage:
            PreferencesService.willBeShowedLineNamesInMessage.value,
        showInstitutionsName:
            PreferencesService.willBeShowedInstitutionsName.value,
      );
    });
  }

  @override
  //Si se cambian las opciones de mostrar el nombre de la línea o el el nombre de las instituciones, entonces el selector regresará al inicio
  void dispose() {
    PreferencesService.willBeShowedLineNamesInMessage.removeListener(
      _loadTransports,
    );
    PreferencesService.willBeShowedInstitutionsName.removeListener(
      _loadTransports,
    );
    super.dispose();
  }
  // ------------------------------------------

  //Selector del transporte
  void _selectTransport(TransportsModel transport) {
    setState(() {
      _transport = transport;
      _line = null;
      _step = _SelectorStep.lines;
    });
  }
  // ------------------------------------------

  //Selector de la línea
  void _selectLine(LinesModel line) {
    setState(() {
      _line = line;
      _step = _SelectorStep.stations;
    });
  }
  // ------------------------------------------

  //Retroceder
  void _goBack() {
    setState(() {
      switch (_step) {
        case _SelectorStep.stations:
          _step = _SelectorStep.lines;
        case _SelectorStep.lines || _SelectorStep.transports:
          _step = _SelectorStep.transports;
      }
    });
  }
  // ------------------------------------------

  // Función de mandar el mensaje a la app elegida por el usuario
  Future<SendMessageResult> sendMessage(String mensajeFinal) async {
    return await SendMessageHelper.sendMessage(mensajeFinal);
  }
  // ------------------------------------------

  // Títulos de los selectores
  String get _title {
    switch (_step) {
      case _SelectorStep.transports:
        return 'Selecciona un \n medio de transporte:';
      case _SelectorStep.lines:
        return 'Selecciona la línea:';
      case _SelectorStep.stations:
        return 'Selecciona la estación:';
    }
  }
  // ------------------------------------------

  double get _titleTopOffset {
    switch (_step) {
      case _SelectorStep.transports:
        return 16;
      case _SelectorStep.lines:
      case _SelectorStep.stations:
        return 25;
    }
  }

  //Pasos de los selectores:
  List<Widget> _listItems(List<TransportsModel> transports) {
    switch (_step) {
      //Paso 1: Seleccionar transportes
      case _SelectorStep.transports:
        return [
          for (final (index, transport) in transports.indexed)
            _StaggeredFadeIn(
              index: index,
              child: ListTile(
                title: Text(transport.name, style: _nunitoFamily),
                onTap: () => _selectTransport(transport),
              ),
            ),
          //Opción de usar la ubicación personalizada
          _StaggeredFadeIn(
            index: transports.length,
            child: ListTile(
              title: Text('Usar ubicación personalizada', style: _nunitoFamily),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
              ),
              onTap: () {
                context.pushNamed(CustomLocationScreen.name);
              },
            ),
          ),

          //------------------------------------------
        ];
      //Paso 2: Seleccionar líneas
      case _SelectorStep.lines:
        final lines = _transport?.lines ?? const <LinesModel>[];
        return [
          for (final (index, line) in lines.indexed)
            _StaggeredFadeIn(
              index: index,
              child: ListTile(
                title: Text(line.name, style: _nunitoFamily),
                onTap: () => _selectLine(line),
              ),
            ),
        ];
      //Paso 3: Seleccionar estaciones
      case _SelectorStep.stations:
        final line = _line!;
        final hasLineNameInMessage = line.lineNameInMessage.isNotEmpty;
        final specialTileCount = hasLineNameInMessage ? 1 : 0;

        final transportsName = _transport?.name ?? '';
        final youSelectedTrains =
            transportsName.contains('Trenes') ||
            transportsName.contains('Valle de México');

        return [
          if (hasLineNameInMessage)
            _StaggeredFadeIn(
              index: 0,
              child: ListTile(
                //Sugerencia de msostrar el nombre de la línea entre las opciones
                title: Text(
                  'Únicamente mencionar el nombre de la línea',
                  style: _nunitoFamily,
                ),
                onTap: () async {
                  // -------------  Construcción del mensaje, si este habla unicamente de la línea elegida
                  final messageBody = PreferencesService.messageBody.value;
                  final namesInLowerCase = line.lineNameInMessage.toLowerCase();
                  final whichLineDIdYouChoosed =
                      (namesInLowerCase.startsWith('tren') ||
                          namesInLowerCase.startsWith('suburbano') ||
                          namesInLowerCase.startsWith('insurgente') ||
                          namesInLowerCase.startsWith('servicio'))
                      ? 'el'
                      : 'la';

                  final String mensajeFinal;
                  if (youSelectedTrains) {
                    if (youSelectedTrains) {
                      mensajeFinal =
                          '$messageBody $whichLineDIdYouChoosed ${line.lineNameInMessage}';
                    } else {
                      mensajeFinal =
                          '$messageBody $transportsName, ${line.lineNameInMessage}';
                    }
                  } else {
                    mensajeFinal =
                        '$messageBody $whichLineDIdYouChoosed ${line.lineNameInMessage}';
                  }

                  final result = await SendMessageHelper.sendMessage(
                    mensajeFinal,
                  );

                  if (result == SendMessageResult.succes) {
                    final newHistoryItem = HistoryItems(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      stationName: line.lineNameInMessage,
                      transportAndLineName:
                          'Transporte: ${_transport?.name ?? ''} - ${line.name}',
                      category: 'LÍNEAS',
                      messageTime: DateTime.now(),
                    );
                    await PreferencesService.saveToHistoryItems(newHistoryItem);
                  }
                },
              ),
            ),
          for (final (index, station) in line.stations.indexed)
            _StaggeredFadeIn(
              index: specialTileCount + index,
              child: ListTile(
                title: Text(station, style: _nunitoFamily),
                onTap: () async {
                  // -------------  Construcción del mensaje, si este habla de una estación
                  final messageBody = PreferencesService.messageBody.value;
                  final showTransportsName =
                      PreferencesService.willBeShowedTransportName.value;

                  final String mensajeFinal;
                  if (showTransportsName) {
                    if (youSelectedTrains) {
                      final lineName = line.name
                          .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
                          .trim();
                      mensajeFinal =
                          '$messageBody la estación del tren $lineName: $station';
                    } else {
                      mensajeFinal =
                          '$messageBody la estación del $transportsName: $station';
                    }
                  } else {
                    mensajeFinal = '$messageBody $station';
                  }

                  final result = await SendMessageHelper.sendMessage(
                    mensajeFinal,
                  );

                  if (result == SendMessageResult.succes) {
                    final newHistoryItem = HistoryItems(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      stationName: station,
                      transportAndLineName:
                          'Transporte: ${_transport?.name ?? ''} - ${line.name}',
                      category: _transportCategory(_transport?.name ?? ''),
                      messageTime: DateTime.now(),
                    );
                    await PreferencesService.saveToHistoryItems(newHistoryItem);
                  } else if (mounted) {
                    await SendMessageHelper().showSendMessageError(
                      context,
                      result,
                    );
                  }
                },
              ),
            ),
        ];
    }
  }
  // ------------------------------------------

  //Construcción de la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Implementación del backgroundColor
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
          child: SelectorScreenLayout(
            /* Return Button: */ showReturnButton:
                _step != _SelectorStep.transports,
            onReturnTap: _goBack,
            //------------------
            selector: FutureBuilder<List<TransportsModel>>(
              future: _transportsFuture,
              builder: (context, snapshot) {
                //Indicador de progreso de carga del selector
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 340,
                    height: double.infinity,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                //---------------------------------------------

                //Captura de errores
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'No se supone que debería de haber esto ;( : ${snapshot.error}',
                    ),
                  );
                }
                //-------------------

                final transports = snapshot.data ?? [];
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  //--------------------------------------------------------

                  //SelectorWidget
                  child: SelectorWidget(
                    key: ValueKey<_SelectorStep>(_step),
                    selectorsTitle: _title,
                    titleTopOffset: _titleTopOffset,
                    listItems: _listItems(transports),
                  ),
                  //----------------
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
