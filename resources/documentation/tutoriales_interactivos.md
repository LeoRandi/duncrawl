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
retrato del appbar; solamente se permite seleccionar por cualquiera de las
dos zonas. Tras seleccionarlo hay otros 500 ms bloqueados, seguidos del tablero
iluminado y la instrucción de arrastrar.

Al planear al menos una casilla, desaparece la sombra y se permite practicar.
Confirm pulsa mientras esté habilitado, y deja de hacerlo al cancelar la ruta o
durante el desplazamiento. Al completar el primer recorrido confirmado, se destaca
la escalera. Close cierra esa última ayuda y finaliza la guía; los movimientos
posteriores no vuelven a mostrarla.

El appbar usa una sola fila: retrato seleccionable a la izquierda y el área de Menu
reservada a la derecha. El nivel y los HP se muestran al seleccionar al personaje,
en el panel inferior. El recorte de selección solo ilumina el retrato y su zona
táctil; Menu permanece oscurecido y bloqueado durante ese paso. El panel inferior
dispone de más altura con el espacio recuperado del encabezado.

## Omitir tutoriales desde ajustes

Tocar la etiqueta **Instant** del ajuste de velocidad del texto revela el interruptor
**Skip tutorials**, inicialmente desactivado. Al pulsar Done se conservan el desbloqueo
y el valor durante la sesión, igual que el resto de los ajustes. Cerrar los ajustes
sin Done descarta los cambios.

Toda nueva guía debe construirse con
`TutorialController(sequence, isEnabled: !settings.skipTutorials)` y omitir también
sus diálogos y esperas iniciales cuando ese ajuste esté activo. El controlador
queda completo desde el principio y permite todos los controles. Para cancelar una
guía en marcha, `skip()` elimina sus esperas, completa la secuencia y notifica a la
pantalla. No se reproducen pasos al volver a activar tutoriales durante una partida;
el ajuste vuelve a aplicarse al empezar otra guía o partida.

La introducción del dungeon sigue esperando a que termine la transición de entrada,
pero con Skip tutorials no espera el segundo inicial ni muestra diálogos, sombras o
ayudas. Los controles se habilitan al terminar la transición.

## Velocidad de desplazamiento

**Movement speed** controla la animación del personaje, independientemente de la
sensibilidad del arrastre y de su cantidad de casillas por turno:

| Valor | Intervalo por casilla |
|---|---|
| Slow | 0,5 s |
| Medium (predeterminado) | 0,3 s |
| Fast | 0,15 s |
| Ultra Fast | 0,05 s |

`MovementSpeed.stepInterval` concentra los intervalos. `DungeonController` recibe
`movementInterval` para leer el ajuste al confirmar una ruta y al reanudarla. El
menú inferior permanece bloqueado durante el desplazamiento a cualquier velocidad.
