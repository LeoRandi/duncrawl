# Crear una planta

Cada planta se define con una plantilla en `lib/features/dungeon/floors/`.
La planta inicial está en `floor_0.dart`; la segunda está en `floor_1.dart`.
`floor_2.dart` incluye agua, hierba, Shallow Water y los primeros murciélagos.
Se accede desde la escalera de la planta 1. La aparición y la escalera se editan
en su plantilla, igual que el resto del mapa.

1. Duplica una plantilla existente, por ejemplo `floor_2.dart` como `floor_3.dart`.
2. Cambia el nombre de la constante a `floor3` y `number` a `3`.
3. Edita las filas: siempre deben ser **15 filas de 15 símbolos**.
4. Registra la nueva plantilla en el mapa de `dungeon_floors.dart`.
5. Define la escalera como `InteractiveDungeonGroundObject` y enlázala con un
   callback que llame a `context.requestFloorChange(3)`.

| Símbolo | Significado |
|---|---|
| `.` | Suelo transitable |
| `_` | Vacío: deja ver el fondo negro y bloquea el movimiento |
| `#` | Pared que bloquea el movimiento |
| `w` | Agua que bloquea el movimiento, dibujada como una `w` gris oscuro |
| `@` | Aparición del personaje sobre suelo; exactamente una por planta |
| `1`, `2`, `3` | Cada marcador en `rows` coloca un Bat sobre suelo normal |

## Dibujar mapas por capas

`floor_1.dart` incluye los mapas de hierba y agua como ejemplo editable. Cada mapa
contiene **15 filas de 15 caracteres**, sin espacios. Las coordenadas empiezan en
cero: `GridPosition(columna, fila)`.

| Propiedad | Símbolos | Uso |
|---|---|---|
| `rows` | `.`, `#`, `_`, `w`, `@`, `1`, `2`, `3` | Estructura, una aparición y posiciones de los Bats. |
| `terrainOverlay` | `.`, `w`, `#`, `_` | Terreno adicional; `.` conserva la casilla base. No admite `@`. |
| `objectRows` | `.`, `g`, `s` | Hierba (`g`), Shallow Water (`s`) o ningún objeto (`.`). |
| `groundObjects` | Objetos Dart | Escaleras, objetos interactivos y colocaciones individuales. |

Los dos mapas adicionales son opcionales y pueden omitirse. El terreno se compone
primero, después se crean los objetos dibujados y finalmente se colocan los objetos
explícitos de `groundObjects`.

Un objeto explícito sustituye los objetos dibujados en su coordenada y despeja el
terreno superpuesto, como el agua. La casilla vuelve al suelo base; el agua dibujada
directamente en `rows` también se convierte en suelo normal. Las paredes y el vacío
estructurales de `rows` se conservan: deben editarse en el mapa base antes de colocar
un objeto allí. Varios objetos **explícitos** pueden compartir coordenada y mantienen
su orden e identidad para sus callbacks.

En la planta 1, la escalera de `(2, 2)` sustituye la hierba dibujada en esa casilla.
El resto del mapa de hierba se conserva exactamente, incluidas las zonas separadas.
El agua ocupa la capa de suelo y bloquea tanto el movimiento como su previsualización.
Se representa con una `w` gris oscuro (`#606060`). Las casillas de agua adyacentes
por sus lados se unen sin líneas interiores; un contorno blanco rodea cada masa,
incluidos sus entrantes y huecos. La hierba usa una `g` gris claro (`#B0B0B0`).
No se generan imágenes.

`s` crea un objeto `DungeonGroundObject.shallowWater`. Se dibuja como `sw`: la `s`
es gris claro y la `w` conserva el gris oscuro del agua. El mismo símbolo aparece
en el retrato. Su descripción reutiliza la del agua y añade debajo
`Shallow: This pool of liquid is walkable`. Es transitable, incluso si está colocado
sobre terreno `w`; al retirar el objeto, el agua profunda vuelve a bloquear el paso.
Sus grupos tienen un borde gris claro (`#B0B0B0`), sin líneas entre casillas
adyacentes. El agua profunda conserva el borde blanco, también en el límite con
agua poco profunda. Ambas descripciones comparten el texto
`Water: liquid. Normally unwalkable, unless you fly`; Shallow Water conserva su
nota adicional debajo.

Los marcadores `1`, `2` y `3` solo se admiten en `rows`. Cada uno crea un
`DungeonEnemy` de tipo `EnemyType.bat` en `DungeonFloor.enemies`, independiente
de los objetos del suelo. Son marcadores estáticos de la capa de personajes, con
una `B` gris; al inspeccionarlos aparecen el nombre Bat y su retrato.

## Selección e inspección

Tocar una casilla vacía (suelo normal o vacío) limpia la selección. Una casilla con
hierba, escalera, agua o pared muestra en el panel inferior su nombre, descripción
y retrato: `g`, icono de escalera, `w` o bloque gris, respectivamente. El marco
pulsante identifica la casilla seleccionada. Shallow Water usa `sw`; los Bats usan
`B` y muestran su nombre y retrato. Unselect también limpia esa selección.

Si coinciden varios objetos, se inspecciona el último de `groundObjects`, que es el
que se dibuja encima. Un Bat tiene prioridad sobre los objetos del suelo bajo él.
El protagonista tiene prioridad al ocupar la casilla; tocarlo o tocar su retrato
del appbar recupera sus controles de movimiento.
Seleccionar otro contenido cancela la ruta pendiente. Inspeccionar no activa
callbacks ni mueve al personaje. Durante desplazamientos, diálogos y cambios de
planta se conservan los bloqueos existentes; el tutorial solo admite sus objetivos
hasta completarse.

`DungeonFloor.inspectTile` resuelve el contenido sin depender de Flutter y
`DungeonController.selectTile` gestiona los cambios de selección. Los nombres,
descripciones y retratos se definen en presentación con `DungeonStrings` y
`TileInspectionView`, de modo que el contenido del mapa sigue siendo independiente
de su texto y sus gráficos.

## Capas, de abajo arriba

1. **Fondo o vacío**: negro puro (`#000000`) por defecto.
2. **Suelo**: las filas de `rows`; las casillas transitables son gris oscuro
   (`#303030`). Las paredes usan un gris más claro (`#606060`), bloquean el paso y
   se unen sin líneas entre paredes adyacentes. Las marcas blancas de la ruta de
   movimiento se dibujan sobre el suelo.
3. **Objetos sobre el suelo**: `objectRows` y `groundObjects`. La escalera y la hierba pertenecen
   a esta capa, no al tipo de suelo. Otros objetos y trampas usan la misma capa.
4. **Personajes**: protagonista y Bats. `@` define la aparición del protagonista;
   `1`, `2` y `3` colocan Bats. Ninguno de estos símbolos cambia el tipo del suelo.
5. **Objetos sobre los personajes**: capa reservada y vacía por ahora.
6. **Niebla y oscuridad**: capa reservada y transparente por ahora.

Para añadir una escalera, conserva un `.` en la casilla y añade un objeto:

```dart
const upstairs = InteractiveDungeonGroundObject(
  type: GroundObjectType.stairsUp,
  position: GridPosition(7, 1),
  stopsMovement: true,
  interactionKind: GroundObjectInteractionKind.stairs,
  onInteract: goUpstairs,
);

// La función puede referenciarse desde una plantilla const.
void goUpstairs(GroundObjectInteractionContext context) {
  context.requestFloorChange(1);
}
```

Incluye `upstairs` en la lista `groundObjects` de la plantilla.

Las coordenadas de objetos empiezan en cero: primero columna y después fila.
La plantilla importa `dungeon_floor.dart`, `grid_position.dart` y, para callbacks,
`ground_object_interaction_context.dart`. Los objetos deben
estar dentro del tablero, sobre suelo transitable; pueden compartir una casilla.
El antiguo símbolo `S` ya no se usa en `rows`.

Las filas se leen de arriba abajo y las columnas de izquierda a derecha.
La aparición central de una cuadrícula de 15 × 15 está en la fila 8, columna 8
(índices `7, 7` en el código).

La plantilla se valida al llamar a `create()`. Los símbolos desconocidos, tamaños
incorrectos y apariciones ausentes o duplicadas generan un `FormatException`.

Los objetos interactivos con `stopsMovement: true` terminan la ruta en su casilla,
sin ejecutar callbacks durante la previsualización. Al llegar a una escalera,
la transición circular se cierra sobre el personaje, cambia de planta en negro y
se abre sobre la nueva aparición. Se conservan su nivel, HP y velocidad, y se
reinician la selección y la ruta. Los controles permanecen bloqueados durante la
transición. El tutorial inicial no vuelve a reproducirse al subir; la planta 1
incluye su propia lección de inspección, registrada en `dungeonTutorials`.

Una escalera definida como `DungeonGroundObject` es un marcador transitable sin
interacción; su aspecto no determina su comportamiento. Las escaleras actuales de
las plantas 0 y 1 son interactivas y conducen a las plantas 1 y 2, respectivamente.

## Interacciones reutilizables

`InteractiveDungeonGroundObject` hereda la posición y el tipo visual de
`DungeonGroundObject` y añade `onInteract`, `stopsMovement` (false por defecto) e
`interactionKind` (`generic` por defecto). El tipo visual no decide la interacción.
El callback es síncrono y recibe `GroundObjectInteractionContext`:

- `object` identifica el objeto que lo ha disparado.
- `trigger` distingue `enteredTile` de `activated`.
- `dungeon` consulta el estado actual, incluso tras otros cambios del mismo callback.
- `updateDungeon` aplica cambios de estado en la misma planta y casilla.
- `requestFloorChange` solicita un cambio de escena para que la presentación
  conserve la transición circular. El objeto no importa Flutter ni conoce animaciones.

El controlador ejecuta los callbacks al entrar en una casilla y al aparecer en una
planta. `interactWith(object)` permite reutilizarlos desde otra acción, como un toque
o un menú; la pantalla decide cuándo ofrecer esa acción. Se ignoran las activaciones
explícitas durante bloqueos y las de objetos que ya no pertenecen a la planta.
Las selecciones, pausas y previsualizaciones no vuelven a activar los objetos.

## Interacciones automáticas y confirmaciones

Los ajustes `Auto-climb stairs` y `Auto-pick-up items` están activados por defecto
y se conservan entre menú y partida durante la sesión. Usa `interactionKind: stairs`
para las escaleras y `interactionKind: pickup` para futuras recogidas. Las acciones
`generic`, como los efectos de una trampa, no dependen de esos dos ajustes.

Con la automatización desactivada, la ruta termina sobre el objeto y se encola una
`GroundObjectInteractionRequest` sin ejecutar su callback. La ventana compartida
pregunta Yes/No y bloquea el juego hasta terminar su salida. Yes ejecuta el callback;
No deja intactos el objeto y el estado de la planta. No se repite la pregunta al
seleccionar, pausar o cambiar ajustes: el personaje debe salir y volver a entrar.
La casilla de origen puede abandonarse aunque el objeto siga en ella.

La respuesta usa la identidad de la petición para que un toque repetido no acepte
otro objeto de la misma casilla. Las peticiones comparten la cola ordenada de
interacciones: cada objeto se confirma por separado y los retirados se omiten.
Las activaciones explícitas con `interactWith` siguen reutilizando el callback.

Los objetos de una misma casilla se resuelven en el orden de `groundObjects`, con el
estado actualizado. Si un callback retira un objeto pendiente, este ya no se ejecuta.
Por ejemplo, un callback consumible puede retirar su propio objeto:

```dart
void consumeObject(GroundObjectInteractionContext context) {
  context.updateDungeon(context.dungeon.removeGroundObject(context.object));
}
```

Un efecto puede actualizar al personaje con `Dungeon.withAdventurer` y
`Adventurer.copyWith`. Esto permite reutilizar el mecanismo para recogidas o trampas
cuando se implementen sus reglas específicas, sin añadir campos de destino ni casos
por tipo visual al controlador.

## Hierba

`DungeonGroundObject.grass(GridPosition(columna, fila))` es un objeto normal y
transitable. Se dibuja como una `g` gris claro (`#B0B0B0`) sin escalarla con el texto
de la interfaz. No se recoge ni activa callbacks. La planta 1 dibuja la hierba en
`objectRows`: quedan 34 casillas después de sustituir la de la escalera. Puedes
seguir añadiendo hierba individual a `groundObjects` cuando necesites una colocación
explícita en vez del mapa de caracteres.

Las tres plantas tienen 56 casillas de pared en el perímetro. La planta 0 conserva
169 casillas de suelo interior; la planta 1 también incluye paredes interiores.
La planta 0 conserva la aparición central `(7, 7)` y la escalera superior `(7, 1)`,
que conduce a la planta 1. Esta empieza en la zona inferior derecha y sitúa su
escalera en la zona superior izquierda. Sus posiciones concretas se editan con
`@` y `groundObjects` en la plantilla.
Las capas quinta y sexta siguen vacías; los gráficos actuales son colores planos
e iconos.
