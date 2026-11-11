# Fragmentos y colores

`ColorShard` identifica desbloqueos independientes: `red`, `gold`, `green`, `blue`
y `lightBlue`. `ShardProgress` es un valor de dominio inmutable sin Flutter;
`unlock` conserva los fragmentos anteriores y repetir uno no cambia el estado.

`DungeonCrawlerApp` posee un `ShardController` y coloca `ShardScope` por encima del
navegador. Así los cambios llegan a tablero, retratos, diálogos, pestañas y menús,
incluidas las rutas flotantes. El progreso dura la sesión de la aplicación; todavía
no hay guardado en disco. Los widgets sin scope conservan los tonos originales.

## Declarar y usar un color

Cada `ShardColor` contiene `grey`, `unlocked` y un único `shard`. No se debe comprobar
si hay «algún color» desbloqueado. `token.of(context)` escucha el progreso y devuelve
solamente el color autorizado por ese fragmento. Un CustomPainter puede recibir el
progreso y usar `token.resolve(progress)`; su `shouldRepaint` debe comprobarlo.

```dart
final color = ShardColors.bat.of(context);
ShardScope.controllerOf(context)?.unlock(ColorShard.red);
```

| Fragmento | Elementos |
|---|---|
| Rojo | Bats, sus nombres y menciones; visión en rojo más claro; botón Main menu. |
| Dorado | Personaje del jugador y sus retratos. |
| Verde | Hierba, nombre y menciones. |
| Azul | Agua profunda y su borde. |
| Azul claro | Agua poco profunda y su borde; prefijo `s` más claro que `w`. |

Escaleras, paredes, suelo y marcos generales conservan sus colores originales.
Solo se obtiene el fragmento rojo en la secuencia actual; los otros están preparados
para sus futuras recompensas.

## Textos y animación reutilizables

`ShardText` y `ShardMentions.spans` colorean palabras completas de contenido conocido,
respetando mayúsculas y plurales de Bat. Los usa el panel, las pestañas, los hints y
los diálogos. `DialogueWindow` conserva la escritura progresiva y los desfases de
las palabras animadas. Para contenido nuevo, registra su mención y token en el
mismo lugar; no repartas expresiones regulares ni comprobaciones de fragmentos.

`showShardReveal(context, shard)` presenta el icono de estrella y un estallido de
píxeles/rayos dibujados con Canvas durante un segundo. Su ruta modal bloquea toques
y navegación atrás. El efecto visual no concede recompensas por sí mismo: el flujo
que lo llama otorga el fragmento cuando termina. La cancelación de la pantalla
evita aplicar una recompensa de un paso que ya no está activo.
