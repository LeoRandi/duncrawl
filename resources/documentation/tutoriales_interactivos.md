# Tutoriales reutilizables

Los componentes de `lib/features/tutorial/presentation/` no conocen las plantas,
personajes ni reglas del dungeon. La configuración de la introducción vive en
`OpeningTutorial.guide`, junto a sus textos iniciales. `FloorOneTutorial` define
la lección de inspección de casillas de la segunda planta.

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

`start(sequence)` sustituye la guía activa, cancela sus esperas y vuelve al primer
paso. También admite `isEnabled: false` para dejar la secuencia completa sin
reproducirla. Así una misma pantalla puede alojar varias lecciones sin duplicar
controladores ni suscripciones.

## Lecciones al entrar en una planta

Registra las lecciones en `dungeonTutorials`, en `floor_tutorials.dart`, usando el
número de planta como clave. Cada `DungeonTutorialLesson` contiene `delay` (espera
tras descubrir la escena), `dialogue` y `guide`. El primer paso de la guía espera
`DungeonTutorialEvent.dialogueFinished` sin habilitar controles.

La pantalla prepara la lección al cambiar de planta con la pantalla en negro y
programa su diálogo al terminar la apertura del iris. Durante la espera, el diálogo
y las pausas entre pasos se bloquean el menú, la selección, la inspección y el
movimiento. Solo se habilitan los controles indicados por cada paso. Las lecciones
se muestran una vez por planta durante la partida y respetan Skip tutorials.

La planta 0 conserva su espera inicial de un segundo. Al llegar a la planta 1 hay
500 ms bloqueados y después dos mensajes de la voz. El fragmento completo
`letters on the floor` es animado; conserva los intervalos de escritura de palabras
animadas y los desfases de letras al revelar el texto al instante.

Al cerrar el diálogo, incluida su animación de salida, hay otros 500 ms bloqueados.
El foco descubre el tablero para inspeccionar una casilla con contenido; tocar
suelo vacío no avanza la guía. Al seleccionar contenido se descubre el panel inferior,
explicando nombre, descripción y retrato. Close termina la lección y permite
seleccionar al personaje, moverlo o limpiar la selección tocando una casilla vacía.

La planta 2 usa `FloorTwoTutorial`: espera 500 ms tras abrirse el iris y reproduce
cuatro mensajes de la misma voz. `Bats` y `eaten` son fragmentos wobbly. Tras cerrar
el diálogo hay 500 ms bloqueados y un foco sobre un Bat. Solo seleccionarlo permite
avanzar; el protagonista y otros contenidos quedan bloqueados. Después se ilumina
el panel inferior para leer descripción, nivel, HP y Movement.

El paso de estadísticas habilita `DungeonTutorialControl.statHelp`, que permite
desplazarse por el texto y abrir `(?)` sin habilitar Unselect, movimiento, pestañas
de capas ni el menú del juego. Close termina la lección y restaura los controles.

## Ayudas reutilizables de estadísticas

`StatInfoButton(statName: ..., explanation: ...)` muestra `(?)` y abre una ventana
pequeña anclada sobre el botón. Recibe texto y estado habilitado, sin depender del
controlador del juego. Usa letra pequeña del tema, fondo negro y borde blanco.
Se mantiene dentro del área visible; el texto puede desplazarse si no cabe.
Cualquier toque dentro o fuera la cierra y consume ese toque, sin activar controles
del juego. La ayuda de Movement explica las casillas por turno y su reducción en
combate; los Bats muestran `5(3)`.

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
`playerMovementInterval` para leer el ajuste al confirmar una ruta y al reanudarla. El
menú inferior permanece bloqueado durante el desplazamiento a cualquier velocidad.


## Efectos entre pasos y primer fragmento

`TutorialStep.effect` permite reutilizar esperas y bloqueos tambi?n para efectos
que no son spotlights. `DungeonPage` interpreta `DialogueSequence` mostrando el
di?logo habitual y se?alando `dialogueFinished` al acabar su salida. Un efecto
`ColorShard` muestra `showShardReveal`, otorga el fragmento al terminar y se?ala
`effectFinished`. El efecto se ejecuta una sola vez por entrada; antes y despu?s
de cada espera se verifica que la pantalla y el paso sigan activos.

Tras cerrar el spotlight de estad?sticas del Bat en la planta 2 se bloquean los
controles durante 500 ms. Se muestran los cuatro mensajes de la voz sobre buscar
una soluci?n, con `this` animado en el ?ltimo. Al cerrar el di?logo y terminar su
salida hay otros 100 ms bloqueados. Despu?s se oscurece el fondo al 50 % y aparece
una estrella roja centrada durante un segundo, con pulsos, p?xeles salientes y rayos.
La estrella usa un icono Material y un CustomPainter; no hay im?genes ni sprites.

Al finalizar se otorga `ColorShard.red`, se actualizan sus colores y se recuperan
los controles. El mismo efecto admite los otros fragmentos. Con Skip tutorials,
la recompensa de la planta se concede al entrar sin esperas, di?logos ni animaci?n.
Los dem?s colores siguen bloqueados. Los fragmentos se conservan durante la sesi?n,
incluso al regresar al men? principal y comenzar otra partida.
