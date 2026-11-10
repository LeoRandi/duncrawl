# Diálogos y tutorial inicial

`OpeningTutorial.dialogue` contiene el título y los cinco textos de la introducción.
Se reproduce en cada partida nueva, un segundo después de terminar la transición
de entrada. Desde que aparece la planta, toda interacción con el juego queda
bloqueada, incluida la espera de un segundo, hasta cerrar el tutorial completo.

Para crear otra conversación, define una `DialogueSequence` con un `speaker` y
una lista no vacía de `DialogueLine`. Cada línea contiene fragmentos
`DialogueFragment`; usa `wobbly: true` en las palabras que deban oscilar.
Los marcadores `**` no forman parte del texto que se muestra.

`showDialogue(context, sequence: ..., anchorKey: ...)` abre la conversación
como una ventana modal. El `GlobalKey` identifica el área que debe ocupar la caja;
el título queda fuera, encima y alineado a la izquierda. El tutorial usa el menú
inferior como ancla, también cuando el diseño coloca ese menú junto al tablero.

- La entrada usa `easeIn` y la salida `easeOut`, ambas de 250 ms.
- Ajustes permite elegir Slow (100 ms), Medium (50 ms, predeterminado), Fast
  (20 ms) o Instant (texto completo al aparecer), respetando emojis y diacríticos.
- Los fragmentos animados se revelan a 100 ms por letra con Slow, Medium y Fast;
  después se recupera la velocidad elegida. Instant también los muestra de golpe.
- Al terminar cada texto aparece Continue con una flecha; el último usa Close y X.
- Tocar la caja mientras escribe revela todo el mensaje actual. No pasa al siguiente;
  para eso se usa Continue. No se cierra tocando el fondo ni con el botón Atrás.
- Las letras animadas comienzan su oscilación al aparecer y la repiten hasta cerrar.
  Comparten el reloj de su palabra y mantienen un desfase por posición, también
  con Instant o al revelar el texto tocando la caja. Las letras que ya estaban
  visibles conservan su movimiento al aparecer las restantes.

La ruta modal oscurece el fondo y bloquea sus entradas táctiles y de foco.
La página pausa el juego desde su entrada y lo reanuda después de esperar el
`Future` de `showDialogue`, que incluye la animación de salida. Así, un movimiento
en curso tampoco avanza mientras se lee. Los temporizadores y animaciones se
liberan al retirar sus widgets.

Los ajustes se comparten entre el menú principal y la partida durante la sesión.
La sensibilidad de movimiento predeterminada es 4/5 (multiplicador de distancia 2).
