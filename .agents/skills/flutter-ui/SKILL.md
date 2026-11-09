---
name: flutter-ui
description: Cómo crear, modificar y revisar páginas, formularios y widgets Flutter. Cubre separación entre vista y estado, lógica de formulario comprobable, reutilización, tema, localización, rendimiento, accesibilidad y ciclo de vida, con atención a interfaces móviles.
---

# Interfaz Flutter

Respeta las instrucciones del usuario, el código real y `analysis_options.yaml`.
Los documentos `resources/documentation/generador_arquitectura_*.md` son plantillas
adaptables; no obligan a crear capas ni dependencias que la funcionalidad no necesita.
En cuestiones de estilo, sigue el fichero que tocas y los lints activos.

Complementa a `clean-code` (tipos, errores y recursos), `readable-code` (flujo) y
`solid-principles` (responsabilidades). Los ejemplos de juego son ilustrativos.
No presupongas paquetes de widgets, un motor de juego ni una biblioteca de estado.

## 1. Piezas de una pantalla

Separa estas responsabilidades cuando la pantalla las necesite; no crees una clase
por fila para una pantalla trivial.

| Pieza posible | Responsabilidad |
|---|---|
| `XxxPageParam` o argumentos del constructor | Datos de entrada y callbacks. |
| Provider, Controller o ViewModel | Cargar, ejecutar acciones, coordinar navegación y liberar recursos. |
| `XxxFormViewModel` | Valores, opciones, cambios y validación de un formulario. |
| `XxxPage` | Estructura, scaffold y conexión con el estado. |
| `XxxScreen` | Cuerpo y secciones. |
| Widget hoja | Dibujar sus datos y emitir callbacks. |

- La vista solo decide layout, visibilidad sencilla, animación y navegación simple.
  Las reglas del juego pertenecen al dominio.
- Un componente compartido recibe lo específico mediante parámetros y callbacks.
- Usa el mecanismo de estado existente. `StatefulWidget` y `setState` bastan para
  estado local pequeño; no añadas Provider, Cubit u otra dependencia por defecto.
- Una vista web, si se necesita, debe adaptarse al espacio. Las ventanas flotantes
  son una decisión de producto, no una obligación arquitectónica.

## 2. Formularios comprobables

Cuando un formulario tiene reglas o cambios dependientes entre campos, mantenlos en
un `XxxFormViewModel` escrito en Dart puro. Un campo sencillo puede usar `Form`,
`TextFormField` y su validador sin crear otra capa.

- Usa una clase por formulario con valores tipados y operaciones con intención.
- Recibe el modelo y las opciones por constructor. Si cambian las opciones, ofrece
  una actualización explícita.
- Las reglas que también rigen una acción del juego se definen en dominio y se
  reutilizan. El formulario solo las anticipa.
- Estado derivado en getters. Cambios relacionados en un método, como
  `selectCreature`.
- Sin `BuildContext`, controladores Flutter, diálogos, navegación ni almacenamiento
  en el formulario puro.
- Guarda los formularios junto a su funcionalidad. Extrae un paquete Dart separado
  cuando haya reutilización o aislamiento real que lo justifique.
- Prueba las transiciones y los casos límite relevantes con datos fijos.

```dart
// Mal: el callback mezcla los cambios del formulario.
onSelected: (creature) {
  selectedCreature = creature;
  selectedSkill = null;
  rebuild();
};

// Bien: ejemplo de una operación comprobable.
onSelected: form.selectCreature;
```

El controlador de pantalla coordina el guardado y el estado de carga. Los valores y
la validación del formulario no deben duplicarse en él y en los widgets.

## 3. Widgets reutilizables y diseño

Busca en `lib/` antes de crear un widget. Comparte un componente repetido desde su
segunda aparición cuando ambos usos deban cambiar juntos.

Si no hay un componente propio, usa las piezas de Flutter que correspondan:

| Para | Punto de partida |
|---|---|
| Estructura y áreas seguras | `Scaffold`, `AppBar`, `SafeArea` |
| Listas | `ListView` o `ListView.builder` |
| Rejillas | `GridView.builder`, slivers si comparten scroll |
| Texto y número | `TextField`, `TextFormField` |
| Selección | `DropdownMenu`, `RadioGroup` si el SDK lo admite, chips |
| Acción | `FilledButton`, `OutlinedButton`, `IconButton` |
| Avisos y progreso | `SnackBar`, `AlertDialog`, indicadores de progreso |
| Espacio y restricciones | `SizedBox`, `Padding`, `ConstrainedBox` |

Comprueba la disponibilidad de las APIs con el SDK fijado en `.fvmrc` antes de usarlas.

- Toma colores y tipografía del tema. Añade tokens compartidos solo cuando exista
  una necesidad repetida.
- Usa la localización existente; si falta, centraliza textos sin inventar una API
  de traducción que el proyecto no tiene.
- Los controles táctiles deben tener áreas cómodas, contraste suficiente y semántica.
  No comuniques un estado solo con color.
- Los botones de solo icono tienen `tooltip`. Añade `Semantics` si la acción o el
  contenido visual no se entiende con los controles estándar.
- Respeta el escalado de texto y el espacio disponible; evita alturas fijas que
  recorten contenido.

## 4. Ciclo de vida y rendimiento

- **Widgets como clases**, no métodos `_buildX()`. Constructor `const` cuando se pueda.
- **`build` barato y sin efectos**: nada de cargas, suscripciones ni controladores
  creados durante cada reconstrucción.
- Crea controladores y suscripciones en `initState` o en el inicio del dueño.
  Libéralos en `dispose` o su equivalente.
- Tras un `await`, comprueba `mounted` antes de usar `BuildContext` o `setState`.
  Si una carga termina tras el cierre de la pantalla, no crees recursos sin dueño.
- Mantén las reconstrucciones cerca del estado que cambia. Un HUD que se actualiza
  a menudo no debería reconstruir todo el menú.
- Para muchos elementos, usa constructores perezosos con altura acotada. Un scroll
  anidado con `shrinkWrap` puede construir toda la lista.
- Decide el layout con `LayoutBuilder` o `MediaQuery.sizeOf(context)`.
- Prefiere `SizedBox`, `Padding` o `ConstrainedBox` si solo necesitas una propiedad
  de `Container`. Recorta únicamente cuando el contenido lo requiera.
- Usa `FadeTransition` o `AnimatedOpacity` para una transición de opacidad.
- Añade claves estables a elementos con estado que se borran o reordenan.

```dart
// Mal: controlador nuevo y todos los elementos creados al reconstruir.
Widget buildList() => ListView(
  controller: ScrollController(),
  children: [for (final creature in creatures) CreatureTile(creature)],
);

// Bien: ejemplo dentro de un espacio con altura acotada.
class CreatureList extends StatelessWidget {
  final List<Creature> creatures;

  const CreatureList({super.key, required this.creatures});

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: creatures.length,
    itemBuilder: (_, index) => CreatureTile(
      creatures[index],
      key: ValueKey(creatures[index].id),
    ),
  );
}
```

## Repaso rápido

- Vista centrada en presentar; reglas del juego fuera de los widgets.
- Formularios complejos comprobables sin Flutter ni servidor.
- Reutilización, tema, textos centralizados y controles accesibles.
- Recursos con dueño, `mounted` tras esperas y listas largas perezosas.
- Layout según el espacio; ninguna dependencia nueva sin necesidad.
