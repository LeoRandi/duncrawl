# Tutoriales reutilizables

Los componentes de `lib/features/tutorial/presentation/` no conocen las plantas,
personajes ni reglas del dungeon. La configuración de la introducción vive en
`OpeningTutorial.guide`, junto a sus textos iniciales.

## Definir otra guía

Crea una `TutorialSequence` con una lista de `TutorialStep`. Usa tus propios enums
para identificar pasos, eventos, controles y anclas; los componentes comunes no
necesitan modificaciones para admitir otros identificadores.

| Campo del paso | Uso |
|---|---|
| `id` | Identificador propio del paso. |
| `advanceOn` | Evento que permite pasar al siguiente. |
| `delay` | Espera para pasar automáticamente; sustituye a `advanceOn`. |
| `enabledControls` | Controles habilitados; vacío bloquea las acciones del juego. |
| `emphasizedControls` | Controles cuya vista debe destacar, por ejemplo con un marco pulsante. |
| `spotlight` | Texto, recortes y posición de la ayuda; opcional. |

```dart
enum LessonEvent { targetSelected, actionFinished }
enum LessonControl { selectTarget, performAction }

const nextLesson = TutorialSequence([
  TutorialStep(id: 'wait', delay: Duration(milliseconds: 500)),
  TutorialStep(
    id: 'select',
    advanceOn: LessonEvent.targetSelected,
    enabledControls: {LessonControl.selectTarget},
  ),
  TutorialStep(
    id: 'act',
    advanceOn: LessonEvent.actionFinished,
    enabledControls: {LessonControl.performAction},
    emphasizedControls: {LessonControl.performAction},
  ),
]);
```

`TutorialController(nextLesson)` gestiona el paso actual. La pantalla comunica
acciones con `signal(event)` y consulta `allows(control)` o `emphasizes(control)`.
Escucha sus cambios con el mecanismo habitual de Flutter. Al terminar la secuencia,
todos los controles quedan habilitados y desaparece el énfasis. `dispose` cancela
cualquier espera pendiente.

## Luces y ventanas

`TutorialSpotlightSpec` recibe el texto y una lista de `TutorialHighlight`:
cada recorte identifica un ancla, una forma circular o rectangular y un margen
absoluto o relativo al tamaño del objetivo. La opacidad predeterminada es del 50 %,
ajustable con `shadeOpacity`.

`TutorialHintPlacement.between` centra la ayuda entre dos objetivos;
`TutorialHintPlacement.bottom` la coloca al fondo del área de otro objetivo.
Una ventana puede incluir `dismissEvent` y `dismissLabel` para ofrecer un cierre
que envíe ese evento al controlador.

La pantalla entrega a `TutorialSpotlight` la especificación, un mapa de
identificadores a `GlobalKey` montados y `onAction: controller.signal`. El componente
ocupa la pantalla completa. Mide los objetivos tras cambios de orientación o tamaño
de texto y conserva visible el cierre en paneles pequeños.

El recorte deja pasar los toques únicamente por las zonas descubiertas. La pantalla
también aplica `allows` a sus callbacks y controles de foco, de modo que una zona
iluminada no habilite acciones ajenas al paso. `InteractionGate` bloquea áreas
completas y `SelectionFrame` aporta el borde pulsante reutilizable.

## Secuencia inicial

Después del diálogo hay 500 ms sin controles. Se muestran el personaje y su
retrato con estadísticas; solamente se permite seleccionar por cualquiera de las
dos zonas. Tras seleccionarlo hay otros 500 ms bloqueados, seguidos del tablero
iluminado y la instrucción de arrastrar.

Al planear al menos una casilla, desaparece la sombra y se permite practicar.
Confirm pulsa mientras esté habilitado, y deja de hacerlo al cancelar la ruta o
durante el desplazamiento. Al completar el primer recorrido confirmado, se destaca
la escalera. Close cierra esa última ayuda y finaliza la guía; los movimientos
posteriores no vuelven a mostrarla.
