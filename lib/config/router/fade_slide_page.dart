import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/gestures.dart' show HorizontalDragGestureRecognizer;
import 'package:flutter/widgets.dart';

/// Ancho (en píxeles lógicos) de la franja que captura el gesto de retroceso.
const double _kBackGestureEdgeWidth = 20.0;

/// Velocidad mínima (en anchos de pantalla por segundo) para que el gesto se
/// complete aunque la pantalla se haya desplazado muy poco.
const double _kBackGestureMinFlingVelocity = 1.0;

/// Duración de la animación que cierra el gesto cuando se suelta el dedo.
const Duration _kBackGestureSettleDuration = Duration(milliseconds: 350);

/// Desplazamiento de la animación de siempre: un leve movimiento vertical, tanto
/// al entrar como al salirse sin que el gesto tome el control.
final Tween<Offset> _kEntranceOffsetTween = Tween<Offset>(
  begin: Offset(0, 0.015),
  end: Offset.zero,
);

/// Desplazamiento del gesto de retroceso: una pantalla completa a la derecha,
/// como el deslizamiento de retroceso de iOS.
final Tween<Offset> _kExitOffsetTween = Tween<Offset>(
  begin: Offset(1, 0),
  end: Offset.zero,
);

/// Plataformas en las que existe el gesto interactivo de retroceso desde el
/// borde izquierdo: iOS y Android.
bool get _isBackGesturePlatform {
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android => true,
    _ => false,
  };
}

/// Curva de la entrada, idéntica a la que usaba el router antes de este cambio.
/// Como en el router original, también es la curva de la salida cuando el
/// retroceso no lo provoca el gesto: fade más el mismo leve slide vertical.
const Curve _kEntranceCurve = Curves.easeInOut;

/// Curva con la que el gesto se asienta cuando se suelta el dedo. Es la curva
/// que usa iOS, y solo se aplica al deslizamiento horizontal del gesto.
const Curve _kBackGestureSettleCurve = Curves.fastEaseInToSlowEaseOut;

/// Página usada por el router.
///
/// Conserva intacta la animación original (fade más micro slide vertical, al
/// entrar y al salirse) y únicamente añade, en iOS y Android, el gesto
/// interactivo de retroceso desde el borde izquierdo. Ese gesto es la única
/// interacción por gestos que se habilita: no hay gestos de avance ni gestos
/// de otro tipo, y es lo único que introduce el deslizamiento horizontal.
class FadeSlidePage<T> extends Page<T> {
  const FadeSlidePage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.canPop,
    super.onPopInvoked,
  });

  /// El contenido que se mostrará en la [Route] creada por esta página.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => FadeSlidePageRoute<T>(this);
}

/// Ruta creada por [FadeSlidePage].
///
/// La entrada y la salida conservan la animación de siempre: fade más un leve
/// slide vertical. La única diferencia es el gesto de retroceso del borde
/// izquierdo de iOS y Android, que además permite arrastrar la pantalla hacia
/// un lado mientras se decide si el retroceso se completa o se cancela.
class FadeSlidePageRoute<T> extends PageRoute<T> {
  FadeSlidePageRoute(FadeSlidePage<T> page) : super(settings: page);

  FadeSlidePage<T> get _page => settings as FadeSlidePage<T>;

  /// `true` desde que el dedo empieza a arrastrar la pantalla hasta que el
  /// gesto se asienta, ya sea volviendo a su sitio o completando el retroceso.
  ///
  /// Es la única bandera que habilita el deslizamiento horizontal, de modo que
  /// el resto de retrocesos (el botón de retroceso, `context.pop()`, un `pop()`
  /// del sistema...) usan la animación original.
  bool _isBackGestureInProgress = false;

  CurvedAnimation? _entranceAnimation;
  CurvedAnimation? _backGestureSettleAnimation;

  /// Expone el controlador de la ruta para que el reconocedor del gesto pueda
  /// mover la transición, igual que hace el gesto nativo de iOS.
  AnimationController? get routeAnimationController => controller;

  /// El gesto de retroceso solo existe en iOS y Android, únicamente en la
  /// pantalla visible y solo cuando hay algo a lo que volver.
  bool get isBackGestureEnabled => _isBackGesturePlatform && popGestureEnabled;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  void install() {
    super.install();
    // Las curvas se crean una sola vez por ruta y se reutilizan en cada
    // fotograma de la transición.
    _entranceAnimation = CurvedAnimation(
      parent: animation!,
      curve: _kEntranceCurve,
    );
    _backGestureSettleAnimation = CurvedAnimation(
      parent: animation!,
      curve: _kBackGestureSettleCurve,
      reverseCurve: _kBackGestureSettleCurve.flipped,
    );
  }

  @override
  void dispose() {
    _entranceAnimation?.dispose();
    _entranceAnimation = null;
    _backGestureSettleAnimation?.dispose();
    _backGestureSettleAnimation = null;
    super.dispose();
  }

  /// Marca el arranque o la finalización del gesto interactivo de retroceso.
  void setBackGestureInProgress(bool value) {
    if (_isBackGestureInProgress == value) {
      return;
    }
    setState(() {
      _isBackGestureInProgress = value;
    });
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _page.child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // En iOS y Android la franja del borde vive dentro de la transición para
    // que viaje junto con la pantalla. En el resto de plataformas no se añade
    // nada.
    final Widget content = _isBackGesturePlatform
        ? _BackGestureStrip<T>(route: this, child: child)
        : child;

    // El deslizamiento horizontal es exclusivo del gesto de retroceso y solo
    // existe mientras el gesto de arrastrar la pantalla está en marcha.
    // Cualquier otro retroceso (el botón, `context.pop()`, un `pop()` del
    // sistema) usa la animación original: fade más el leve slide vertical.
    final bool isBackGestureSliding =
        _isBackGesturePlatform && _isBackGestureInProgress;

    // Durante el arrastre la posición sigue al dedo sin curvas; al soltar el
    // dedo toma la curva de iOS.
    final Animation<double> settleDriver = _isBackGestureInProgress
        ? animation
        : _backGestureSettleAnimation!;
    final Animation<Offset> position = isBackGestureSliding
        ? _kExitOffsetTween.animate(settleDriver)
        : _kEntranceOffsetTween.animate(_entranceAnimation!);

    // El gesto se desliza sin desvanecerse; la animación de siempre se
    // desvanece. La forma del árbol no cambia nunca, para que la franja del
    // borde no se destruya a mitad del gesto.
    return SlideTransition(
      position: position,
      child: FadeTransition(
        opacity: isBackGestureSliding
            ? kAlwaysCompleteAnimation
            : _entranceAnimation!,
        child: content,
      ),
    );
  }
}

/// Franja invisible en el borde izquierdo que detecta el arrastre de retroceso.
class _BackGestureStrip<T> extends StatefulWidget {
  const _BackGestureStrip({required this.route, required this.child});

  final FadeSlidePageRoute<T> route;
  final Widget child;

  @override
  State<_BackGestureStrip<T>> createState() => _BackGestureStripState<T>();
}

class _BackGestureStripState<T> extends State<_BackGestureStrip<T>> {
  _BackGestureController<T>? _gestureController;

  late final HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();

    // Si el widget desaparece a mitad del gesto hay que cerrar el gesto de
    // usuario que el Navigator tiene abierto.
    final _BackGestureController<T>? gestureController = _gestureController;
    if (gestureController != null) {
      _gestureController = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (gestureController.navigator.mounted) {
          gestureController.navigator.didStopUserGesture();
        }
        gestureController.onSettled();
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _gestureController = _startBackGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double? width = context.size?.width;
    if (width == null || width == 0) {
      return;
    }
    _gestureController?.dragUpdate(
      _toLogical((details.primaryDelta ?? 0) / width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    final double? width = context.size?.width;
    final _BackGestureController<T>? gestureController = _gestureController;
    _gestureController = null;
    if (width == null || width == 0) {
      gestureController?.dragEnd(0.0);
      return;
    }
    gestureController?.dragEnd(
      _toLogical(details.velocity.pixelsPerSecond.dx / width),
    );
  }

  void _handleDragCancel() {
    final _BackGestureController<T>? gestureController = _gestureController;
    _gestureController = null;
    gestureController?.dragEnd(0.0);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.route.isBackGestureEnabled) {
      _recognizer.addPointer(event);
    }
  }

  _BackGestureController<T> _startBackGesture() {
    final AnimationController? controller =
        widget.route.routeAnimationController;
    final NavigatorState? navigator = widget.route.navigator;
    assert(controller != null && navigator != null);
    widget.route.setBackGestureInProgress(true);
    return _BackGestureController<T>(
      navigator: navigator!,
      controller: controller!,
      getIsCurrent: () => widget.route.isCurrent,
      getIsActive: () => widget.route.isActive,
      onSettled: () => widget.route.setBackGestureInProgress(false),
    );
  }

  /// Convierte el desplazamiento de la pantalla a coordenadas lógicas, igual
  /// que hace el gesto nativo, para respetar el sentido de escritura.
  double _toLogical(double value) {
    return switch (Directionality.of(context)) {
      TextDirection.rtl => -value,
      TextDirection.ltr => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    // En dispositivos con muesca la zona arrastrable es más ancha en el lado
    // que la tiene.
    final double edgeWidth = math.max(
      MediaQuery.paddingOf(context).left,
      _kBackGestureEdgeWidth,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          top: 0.0,
          bottom: 0.0,
          width: edgeWidth,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// Controla el gesto de retroceso moviendo el controlador de la ruta.
///
/// Trabaja en coordenadas lógicas: `1.0` es la pantalla encima y `0.0` la
/// pantalla descartada.
class _BackGestureController<T> {
  _BackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsCurrent,
    required this.getIsActive,
    required this.onSettled,
  }) {
    navigator.didStartUserGesture();
  }

  final NavigatorState navigator;
  final AnimationController controller;
  final bool Function() getIsCurrent;
  final bool Function() getIsActive;
  final VoidCallback onSettled;

  /// El arrastre cambió [delta]; el recorrido total va de 0.0 a 1.0.
  void dragUpdate(double delta) {
    final double value = (controller.value - delta).clamp(0.0, 1.0);
    if (value == controller.value) {
      return;
    }
    controller.value = value;
  }

  /// El arrastre terminó con una velocidad horizontal de [velocity] expresada
  /// como fracción del ancho de pantalla por segundo.
  void dragEnd(double velocity) {
    const Curve animationCurve = _kBackGestureSettleCurve;
    final bool isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      // La pantalla ya no es la visible: si sigue en la pila debe terminar de
      // salirse, aunque apenas se haya movido.
      animateForward = getIsActive();
    } else if (velocity.abs() >= _kBackGestureMinFlingVelocity) {
      // Lanzamiento: gana la dirección del gesto.
      animateForward = velocity <= 0;
    } else {
      // Sin lanzamiento: gana la mitad de la pantalla recorrida.
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      controller.animateTo(
        1.0,
        duration: _kBackGestureSettleDuration,
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        navigator.pop();
      }
      // El pop puede haber terminado en línea si ya estaba en el destino.
      if (controller.isAnimating) {
        controller.animateBack(
          0.0,
          duration: _kBackGestureSettleDuration,
          curve: animationCurve,
        );
      }
    }

    if (controller.isAnimating) {
      late final AnimationStatusListener listener;
      listener = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(listener);
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          onSettled();
        }
      };
      controller.addStatusListener(listener);
    } else {
      navigator.didStopUserGesture();
      onSettled();
    }
  }
}
