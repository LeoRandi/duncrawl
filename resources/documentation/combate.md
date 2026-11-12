# Implementación del combate en tres fases

El combate sucede en el mismo tablero y modifica el mismo estado de la mazmorra.
Los enemigos no se copian a una escena de batalla: conservan identidad, posición
y salud al entrar y salir de un encuentro.

## Fase 1: actores y movimiento — implementada

Objetivo: preparar un mundo coherente antes de añadir turnos y ataques.

- `DungeonActor` comparte identidad, estadísticas, derrota y el cálculo de
  movimiento en combate: `max(0, movementSpeed - 2)`.
- El aventurero tiene un ID estable. Cada enemigo creado por una plantilla recibe
  `floor:<número>:enemy:<columna inicial>:<fila inicial>`. Los marcadores repetidos
  también producen IDs distintos. El ID se conserva al copiar o mover al actor;
  las coordenadas actuales nunca se usan para recalcularlo. Los IDs identifican
  actores dentro de una partida; reconstruir la misma plantilla los reproduce.
- `Dungeon` consulta actores por ID y posición. Sus operaciones inmutables
  actualizan y retiran enemigos sin modificar instantáneas anteriores.
- `DungeonFloor.canEnter` valida terreno. `Dungeon.canOccupy` añade ocupación y
  `canStepFrom` añade adyacencia y comprueba que el actor pueda actuar.
- `MovementPlan` y `stepActorTo` comparten esa validación. `stepTo` conserva la API
  de movimiento del aventurero. Todos los actores bloquean su casilla hasta que
  se retiran del mundo; tener salud cero no elimina una entidad automáticamente.
- `MovementPlan.start(movementBudget: ...)` admite un saldo explícito. Previsualizar
  o deshacer una ruta no modifica el mundo. Todavía no hay saldo de turnos que
  consumir: esa responsabilidad corresponde a la fase 2.
- El controlador revalida cada paso confirmado. Si el mundo cambia y bloquea la
  ruta, termina el movimiento sin repetir interacciones en la casilla actual.
- Selección, claves de widgets y anclajes de tutorial usan los IDs de los actores.
  Al mover o actualizar un enemigo seleccionado, se refresca la pila de su nueva
  casilla. Al retirarlo, se limpia la selección.

Esta fase preparó las entidades y el movimiento. La fase 2 añade detección,
turnos y acciones; la persistencia queda para la fase 3.

Validación: pruebas de identidad, ocupación, previsualización, interrupción de rutas
y conservación de selección y widgets, además de las pruebas existentes.

## Fase 2: encuentro y bucle jugable — implementada

Objetivo: entrar en combate desde exploración y volver con sus consecuencias.

1. Añadir estado de encuentro con IDs de participantes, lado activo, ronda y saldos
   de movimiento/acciones. Mantenerlo separado de `MovementPhase`, que describe
   una interacción de interfaz. La salud y las posiciones siguen en el mundo.
2. Introducir comandos y transiciones síncronas en Dart puro. El controlador
   solicita acciones y presenta sus eventos; animaciones y temporizadores no
   deciden daño, muertes o recompensas.
3. Resolver cada paso en este orden: movimiento, efectos automáticos, muertes,
   detección e interacciones opcionales. Revalidar las interacciones aplazadas.
4. Compartir visibilidad entre detección y contornos del tablero. Comprobarla al
   entrar en una planta y tras cambios relevantes de posición o visibilidad.
5. Al detectar hostiles, cancelar el resto de la ruta de exploración e iniciar
   un encuentro sobre las posiciones actuales. El grupo actúa primero en los
   encuentros ordinarios.
6. Implementar turno del grupo y turno enemigo: movimiento divisible, una acción
   por actor y fin de turno explícito. La IA elige comandos sujetos a las mismas
   reglas que el jugador. Los refuerzos se incorporan en un límite definido.
7. Añadir ataque básico, daño, retirada de derrotados, victoria y derrota.
   Terminar el encuentro conserva los cambios y deja una ruta vacía; perder
   visibilidad por sí solo no termina el combate.
8. Secuenciar presentación y pausa sin ejecutar dos acciones a la vez ni aceptar
   callbacks antiguos después de abandonar una escena.

Criterios: detección a mitad de ruta, prioridad frente a escaleras, movimiento
que no se recarga al cancelar una previsualización, enemigos derrotados que no
actúan y resultados idénticos con distintas velocidades de animación.

### Reglas y controles actuales

- `DungeonActor` incluye Strength, Dexterity y Special. Valores iniciales del
  aventurero: STR 2, DEX 1, Special 1. Bats: STR 1, DEX 1, Special 1. Dexterity y
  Special todavía no modifican reglas de combate.
- Un ataque básico tiene daño base 0 y suma STR. No hay daño mínimo, defensa,
  aciertos aleatorios ni críticos. Alcanza una única casilla ortogonal adyacente;
  las diagonales quedan fuera. El aventurero apunta desde el panel, con
  independencia de la selección.
- `GameState` es el estado autoritativo: mazmorra y encuentro. `GameRules` resuelve
  `MoveActor`, `AttackActor` y `EndActorTurn`, devuelve instantáneas y eventos, y no
  importa Flutter. La salud y las posiciones nunca se duplican en el encuentro.
- Cada actor tiene movimiento reducido en dos, con mínimo cero, y una acción
  por turno. El aventurero puede repartir el movimiento antes y después de atacar.
  Cambiar de selección o cancelar una ruta no restaura lo ya gastado.
- Los Bats tienen movimiento base 4 y movimiento de combate 2, mostrado como
  `4(2)`. Su cadencia de 150 ms por casilla se conserva.
- Tras la fase del aventurero, cada enemigo participante mueve y ataca mediante
  los mismos comandos. La búsqueda de rutas evita paredes, agua profunda y otros
  actores. Si no puede llegar, termina su turno. Los refuerzos detectados durante
  una fase enemiga esperan a la siguiente fase enemiga para actuar.
- `DungeonVisibility` comparte radio y línea de visión entre detección y tablero.
  Las paredes y el vacío intermedios bloquean la vista, incluidas las esquinas
  cerradas. Perder la visión no termina un encuentro ya iniciado.
- `DungeonEnemy.alertRadius` vale el doble de la visión de forma predeterminada,
  incluso si cambia esta última; puede fijarse explícitamente por enemigo. Usa
  distancia ortogonal y no exige línea de visión: representa oír el combate.
  Estar cerca sin combate no alerta a nadie. Una vez iniciado, un aventurero o
  enemigo participante dentro del radio alerta a ese enemigo, que puede avisar
  a otros. La propagación no depende del orden de la lista y no duplica actores.
  Un primer golpe letal alerta antes de retirar a su víctima. Los refuerzos que
  llegan durante una fase enemiga esperan a la siguiente para actuar.
- El controlador aplica cada paso, resuelve efectos `automatic`, llama a
  `GameRules.refresh` y después atiende interacciones opcionales. Este proceso
  termina antes de publicar la nueva instantánea. `automatic` identifica efectos
  inmediatos como trampas; `generic`, `pickup` y `stairs` conservan sus colas y
  confirmaciones. Los enemigos aún no activan callbacks de objetos del suelo.
- Durante el combate se aplazan las escaleras y otras interacciones opcionales.
  Al vencer se revalidan: si el jugador ya abandonó su casilla, no se ejecutan.
- En exploración, el menú muestra nivel, HP, movimiento, Strength, Dexterity y
  Special. Las criaturas no muestran descripción ni el valor numérico de visión.
  El panel de acciones oculta las estadísticas y usa su espacio para los botones;
  el icono de información permite volver a consultarlas durante el combate.
  El tablero y el panel conservan exactamente su tamaño y posición, también al
  apuntar o cambiar de turno. La ronda y el turno ocupan una pestaña en la fila
  existente de `Over` y `Below`. No se muestran avisos de detección o victoria.
- `Move` abre el panel de control; arrastrar dentro prepara una ruta. `Strike`
  cambia ese mismo panel a apuntado ortogonal. `Confirm` ejecuta la acción;
  `Cancel` limpia su previsualización. `End turn` inicia la fase enemiga.
- El tablero mantiene sus posiciones al entrar y salir de combate. Muestra
  participantes con `!`, el enemigo activo con un marco y los impactos con daño
  flotante. La victoria conserva salud, objetos y enemigos supervivientes; la
  derrota bloquea acciones y permite volver al menú principal.
- El alcance de movimiento de los enemigos participantes permanece delimitado en
  rojo, independientemente de la selección o del fragmento rojo. Usa el movimiento
  completo de combate, sin descontar pasos gastados ni obstáculos: las paredes y
  el agua profunda no recortan esta previsualización. Las reglas de movimiento
  real siguen respetando el terreno. El contorno tarda seis segundos en iluminarse
  y otros seis en atenuarse; nunca desaparece por completo.
- `EnemyRanges` une las casillas por tipo antes de dibujar cada perímetro. Los
  alcances de movimiento y alerta de varios enemigos no generan líneas internas.
  Se actualizan al moverse o desaparecer sus participantes.
- La alerta se muestra para enemigos inspeccionados y participantes en combate.
  Es gris hasta desbloquear `ColorShard.orange`; usa un color naranja independiente
  del fragmento rojo. La inspección fuera de combate conserva la visión con línea
  de vista. Estos radios no se añaden a la lista de estadísticas visibles.
- Los temporizadores secuencian comandos y presentación. Pausar cancela las
  esperas; reanudar conserva el turno. Abandonar la pantalla cancela los timers.
  La animación de impacto no aplica daño ni decide muertes.
- La cadencia del jugador usa el ajuste de velocidad; la de los enemigos depende
  de `EnemyType.stepInterval`. Los Bats empiezan con 150 ms por paso (rápidos,
  por debajo del máximo de 50 ms del jugador). Cada acción vuelve a programar
  la espera según la especie activa, también al pasar al siguiente enemigo o
  reanudar la partida. No modifica las casillas disponibles por turno.

`DungeonPage.initialDungeon` permite iniciar un escenario concreto y escoge el
tutorial de su planta. La partida normal sigue empezando en la planta 0.

Las pruebas cubren reglas, controlador e interfaz, con partidas completas,
pausa, prioridad frente a escaleras, derrota, refuerzos, paredes y formatos
compactos en vertical y horizontal con texto ampliado.

### Panel de control implementado

`ActionControls` ocupa el panel existente de 216 px sin mover el tablero, el
retrato ni la pestaña de turno. Tiene dos modos fijos, `Move` y `Strike`, una
zona negra de control y la fila `Cancel`, `Confirm`, `End turn`. Solo el texto de
la caja central es gris oscuro (`DungeonColors.controlPadText`); los botones y
el icono de información permanecen blancos. Confirmar resalta el borde, sin un
relleno blanco que oculte su etiqueta.

En el turno del jugador, `Move` y `Strike` pasan a gris al gastar su recurso.
Preparar una ruta no gasta movimiento. Cuando movimiento y acción se agotan,
el borde de `End turn` pulsa al terminar la ejecución, sin desplazar el botón.
La indicación se retira durante la fase enemiga y se reinicia en el nuevo turno;
respeta la preferencia de reducir animaciones mediante `SelectionFrame`.

- En exploración, seleccionar al aventurero y pulsar `Move` abre el panel.
  En combate se abre automáticamente. El icono de información vuelve a la
  inspección también durante el turno del jugador y descarta la previsualización
  pendiente, sin recargar recursos. La inspección conserva la pestaña de turno y
  ofrece `Actions` para volver al control, incluso al inspeccionar otro enemigo,
  terreno o ninguna selección. Cambiar de panel no termina el turno.
- `Move`: arrastrar dibuja una ruta ortogonal, retroceder la deshace y levantar
  el dedo conserva la previsualización. Otro arrastre continúa la ruta. La
  sensibilidad respeta Settings. Una cancelación del puntero restaura la ruta
  anterior al gesto, conservando lo preparado en gestos previos.
- `Strike`: arrastrar apunta a norte, este, sur u oeste desde el aventurero,
  con una zona muerta central. El tablero marca la casilla y el panel anticipa
  el daño o indica que no hay objetivo. Levantar el dedo conserva la mira.
- Las cuatro direcciones del panel también se pueden pulsar y tienen acciones
  semánticas. Arrastrar el tablero, el retrato o los botones no mueve al jugador.
- Solo `Confirm` ejecuta una acción. `Cancel` limpia la previsualización sin
  gastar recursos. Cambiar de modo descarta la previsualización pendiente.
- `DungeonController.controlMode` y `controlledActorId` separan control,
  inspección y objetivo. Apuntar no selecciona al enemigo. Inspeccionar una
  casilla mientras el panel está abierto conserva la ruta y la mira.
- Durante una ejecución o fase enemiga se bloquea la entrada; un dedo que
  permanezca apoyado al confirmar no puede preparar otra ruta al desbloquearse.

### Ajustes para probar el combate

Ambos ajustes están desactivados de forma predeterminada y se aplican al pulsar
`Done` en Settings, tanto desde el menú principal como durante una partida.

- `colorblind hate` muestra todos los fragmentos desbloqueados mientras está
  activo. Al desactivarlo reaparecen solo los ganados, incluidos los obtenidos
  mientras el ajuste estaba activo.
- `Test bats on floor 0` añade dos Bats en `(11, 12)` y `(12, 12)`. Si una casilla
  está ocupada, usa otra libre próxima en esa esquina. Desactivarlo retira solo
  esos Bats. No reinicia la planta ni modifica salud, posición u objetos. El
  ajuste se recuerda para la entrada en la planta 0 y no afecta a otras plantas.

## Fase 3: integración y progresión — pendiente

Objetivo: conectar el combate con las funciones de la demo y su continuidad.

- Añadir la habilidad fuerte del aventurero y la cura de los Bats.
- Modelar facciones, grupo y domesticación usando las mismas entidades y reglas.
  El fragmento verde y el permiso para domesticar son recompensas distintas de
  un mismo hito, no una dependencia entre reglas y colores de la interfaz.
- Aplicar recompensas de jefes una sola vez y registrar el progreso antes de
  mostrar su animación. Conectar desbloqueos de colores, sprites y controles.
- Integrar tutoriales, consumibles, trampas, misiones, bestiario y el registro de
  visitas a plantas necesario para el logro de evitar combates.
- Conservar el estado de cada planta visitada antes de habilitar el descenso.
  Las plantillas inicializan plantas nuevas; no restauran plantas ya visitadas.
- Guardar una instantánea coherente en límites de acciones resueltas y restaurar
  actores, encuentros, plantas, progreso y recompensas reclamadas.
- Definir y probar escape e interacciones con escaleras durante un encuentro.

Criterios: recompensa única aunque se interrumpa su presentación, enemigos y
objetos que no reaparecen al revisitar plantas, carga sin repetir turnos y un Bat
domesticado que conserva su identidad, salud y habilidades.
