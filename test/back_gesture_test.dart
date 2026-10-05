import 'package:anuncia_mi_llegada/config/router/fade_slide_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const Offset _edgeStart = Offset(10, 300);
const Offset _edgeDrag = Offset(320, 0);

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('first'))),
        ),
        GoRoute(
          path: '/second',
          pageBuilder: (context, state) => const FadeSlidePage<void>(
            child: Scaffold(body: Center(child: Text('second'))),
          ),
        ),
      ],
    );
  });

  tearDown(() => router.dispose());

  /// Corre [body] fingiendo la plataforma [platform]. La bandera de debug tiene
  /// que volver a su valor original dentro del test, no en el `tearDown`.
  void platformTestWidgets(
    String description,
    TargetPlatform platform,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await body(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Future<void> swipeBack(WidgetTester tester) async {
    await tester.timedDragFrom(
      _edgeStart,
      _edgeDrag,
      const Duration(milliseconds: 150),
    );
    await tester.pumpAndSettle();
  }

  /// Posición horizontal del contenido de la pantalla `/second`, ya con las
  /// transformaciones de la transición aplicadas.
  double secondScreenX(WidgetTester tester) =>
      tester.getCenter(find.text('second')).dx;

  double fadeOf(WidgetTester tester) =>
      tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value;

  platformTestWidgets(
    'iOS: el arrastre desde el borde izquierdo regresa',
    TargetPlatform.iOS,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);

      await swipeBack(tester);

      expect(find.text('second'), findsNothing);
      expect(find.text('first'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'iOS: un arrastre incompleto se cancela y no regresa',
    TargetPlatform.iOS,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();

      // Sin velocidad y sin pasar la mitad de la pantalla: el gesto se cancela.
      await tester.dragFrom(_edgeStart, const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'iOS: la pantalla sigue al dedo durante el arrastre',
    TargetPlatform.iOS,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();
      expect(secondScreenX(tester), 400);

      final gesture = await tester.startGesture(_edgeStart);
      await gesture.moveBy(const Offset(200, 0));
      await tester.pump();

      // Un cuarto de ancho recorrido: la pantalla lleva un cuarto de ancho.
      expect(secondScreenX(tester), 600);
      // Mientras el gesto manda, la pantalla se desliza sin desvanecerse.
      expect(fadeOf(tester), 1.0);

      // Un arrastre tan corto se cancela al soltar.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(secondScreenX(tester), 400);
      expect(fadeOf(tester), 1.0);
    },
  );

  platformTestWidgets(
    'iOS: sin historial el arrastre del borde no hace nada',
    TargetPlatform.iOS,
    (tester) async {
      await pumpApp(tester);

      await swipeBack(tester);

      expect(find.text('first'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'iOS: el botón de retroceso sigue funcionando',
    TargetPlatform.iOS,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();

      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('second'), findsNothing);
      expect(find.text('first'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'Android: el arrastre desde el borde izquierdo regresa',
    TargetPlatform.android,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);

      await swipeBack(tester);

      expect(find.text('second'), findsNothing);
      expect(find.text('first'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'Android: un arrastre incompleto se cancela y no regresa',
    TargetPlatform.android,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();

      await tester.dragFrom(_edgeStart, const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'Android: la pantalla sigue al dedo durante el arrastre',
    TargetPlatform.android,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();
      expect(secondScreenX(tester), 400);

      final gesture = await tester.startGesture(_edgeStart);
      await gesture.moveBy(const Offset(200, 0));
      await tester.pump();

      expect(secondScreenX(tester), 600);
      expect(fadeOf(tester), 1.0);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(secondScreenX(tester), 400);
    },
  );

  platformTestWidgets(
    'Android: sin historial el arrastre del borde no hace nada',
    TargetPlatform.android,
    (tester) async {
      await pumpApp(tester);

      await swipeBack(tester);

      expect(find.text('first'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'Android: el botón de retroceso conserva el fade sin deslizamiento',
    TargetPlatform.android,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Igual que en iOS: el botón no arrastra la pantalla de lado.
      expect(secondScreenX(tester), 400);
      expect(fadeOf(tester), lessThan(1.0));

      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'Otras plataformas: el arrastre desde el borde no hace nada',
    TargetPlatform.linux,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();
      expect(secondScreenX(tester), 400);

      final gesture = await tester.startGesture(_edgeStart);
      await gesture.moveBy(const Offset(200, 0));
      await tester.pump();

      expect(secondScreenX(tester), 400);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'Android: el botón de retroceso sigue funcionando',
    TargetPlatform.android,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();

      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
    },
  );

  platformTestWidgets(
    'La entrada conserva el fade + desplazamiento vertical',
    TargetPlatform.iOS,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Al entrar la pantalla no se desplaza de lado: solo aparece y sube.
      expect(secondScreenX(tester), 400);
      expect(fadeOf(tester), lessThan(1.0));
      expect(fadeOf(tester), greaterThan(0.0));
    },
  );

  platformTestWidgets(
    'Android: la entrada conserva el fade + desplazamiento vertical',
    TargetPlatform.android,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(secondScreenX(tester), 400);
      expect(fadeOf(tester), lessThan(1.0));
      expect(fadeOf(tester), greaterThan(0.0));
    },
  );

  platformTestWidgets(
    'iOS: sin el gesto, la salida conserva el fade + desplazamiento vertical',
    TargetPlatform.iOS,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // El botón de retroceso no se desliza de lado: se desvanece y baja.
      expect(secondScreenX(tester), 400);
      expect(fadeOf(tester), lessThan(1.0));
    },
  );

  platformTestWidgets(
    'Android: la salida conserva el fade + desplazamiento vertical',
    TargetPlatform.android,
    (tester) async {
      await pumpApp(tester);

      router.push('/second');
      await tester.pumpAndSettle();

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(secondScreenX(tester), 400);
      expect(fadeOf(tester), lessThan(1.0));
    },
  );
}
