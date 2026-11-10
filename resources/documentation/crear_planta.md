# Crear una planta

Cada planta se define con una plantilla en `lib/features/dungeon/floors/`.
La planta inicial está en `floor_0.dart`.

1. Duplica `floor_0.dart` como `floor_1.dart`.
2. Cambia el nombre de la constante a `floor1` y `number` a `1`.
3. Edita las filas: siempre deben ser **15 filas de 15 símbolos**.

| Símbolo | Significado |
|---|---|
| `.` | Suelo transitable |
| `_` | Vacío: deja ver el fondo negro y bloquea el movimiento |
| `#` | Pared que bloquea el movimiento |
| `@` | Aparición del personaje sobre suelo; exactamente una por planta |

## Capas, de abajo arriba

1. **Fondo o vacío**: negro puro (`#000000`) por defecto.
2. **Suelo**: las filas de `rows`; las casillas transitables son gris oscuro
   (`#303030`). Las marcas blancas de la ruta de movimiento se dibujan sobre este suelo.
3. **Objetos sobre el suelo**: `groundObjects`. La escalera pertenece a esta capa,
   no al tipo de suelo. En el futuro podrán incorporarse hierba, objetos o trampas.
4. **Personajes**: su posición y estado durante la partida. Ahora solo el protagonista.
   El símbolo `@` define dónde aparece; no dibuja un segundo personaje estático.
5. **Objetos sobre los personajes**: capa reservada y vacía por ahora.
6. **Niebla y oscuridad**: capa reservada y transparente por ahora.

Para añadir una escalera, conserva un `.` en la casilla y añade un objeto:

```dart
groundObjects: [
  DungeonGroundObject(
    type: GroundObjectType.stairsUp,
    position: GridPosition(7, 1),
  ),
],
```

Las coordenadas de objetos empiezan en cero: primero columna y después fila.
La plantilla importa `dungeon_floor.dart` y `grid_position.dart`. Los objetos deben
estar dentro del tablero, sobre suelo transitable; pueden compartir una casilla.
El antiguo símbolo `S` ya no se usa en `rows`.

Las filas se leen de arriba abajo y las columnas de izquierda a derecha.
La aparición central de una cuadrícula de 15 × 15 está en la fila 8, columna 8
(índices `7, 7` en el código).

La plantilla se valida al llamar a `create()`. Los símbolos desconocidos, tamaños
incorrectos y apariciones ausentes o duplicadas generan un `FormatException`.

Para probar otra planta como inicio, importa su fichero en `dungeon_page.dart`
y sustituye `Dungeon.start(floor0.create())` por
`Dungeon.start(floor1.create())`. Las transiciones entre plantas aún no están
implementadas; la escalera es un marcador visual.

La planta 0 contiene 225 casillas de suelo gris oscuro, la aparición central y
una escalera en la tercera capa, cerca del centro superior. El fondo negro está
detrás del suelo; las capas quinta y sexta están vacías. Los gráficos actuales
son colores planos e iconos.
