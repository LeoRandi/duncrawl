---
name: readable-code
description: Cómo escribir y refactorizar código Dart/Flutter que se entienda a la primera. Cubre guard clauses, llaves, alcance de try/catch y try/finally, condiciones con nombre, Information Expert, orden y formato, y comentarios. Úsala siempre que escribas, refactorices o revises código.
---

# Código legible

Escribe para alguien que llega sin contexto, con prisa y buscando un bug.

Respeta las instrucciones del usuario, el código real y `analysis_options.yaml`.
Los documentos `resources/documentation/generador_arquitectura_*.md` son plantillas
adaptables; no obligan a crear capas ni dependencias que la funcionalidad no necesita.
En cuestiones de estilo, sigue el fichero que tocas y los lints activos.

Complementa a `clean-code` (nombres y errores), `solid-principles` (responsabilidades)
y `flutter-ui` (páginas y widgets). Los ejemplos de juego son ilustrativos.

## 1. Lo raro arriba, el camino feliz abajo

Comprueba primero los casos que cortan y sal en cuanto los detectes.

```dart
// Mal: el caso normal queda enterrado.
bool canAct(Creature? creature) {
  if (creature != null) {
    if (creature.isAlive) {
      if (creature.hasEnergy) {
        return true;
      }
    }
  }
  return false;
}

// Bien
bool canAct(Creature? creature) {
  if (creature == null || !creature.isAlive) {
    return false;
  }

  return creature.hasEnergy;
}
```

- Sin `else` después de `return`, `throw`, `continue` o `break`.
- Cuando una rama devuelve `null`, `false` o vacío para cortar, prefiere una guarda
  si aclara el camino normal.
- Línea en blanco entre las guardas y el resto.
- En bucles, usa `continue` para descartar pronto.
- Más de dos niveles de anidamiento sugieren extraer o invertir condiciones.

## 2. Llaves

Sigue los lints activos y el estilo del fichero. El proyecto incluye
`package:flutter_lints/flutter.yaml` y no desactiva expresamente sus reglas de llaves.
No presupongas excepciones de estilo de otros repositorios.

```dart
if (isStarted) {
  return;
}

for (final creature in creatures) {
  enqueue(creature);
}
```

## 3. `try/catch` y `try/finally`

Cuándo capturar y qué devolver está en «Errores» de `clean-code`.
Envuelve solo la llamada cuyo fallo se sabe gestionar; continúa fuera del `try`.

```dart
// Esquemático: el adaptador comunica un fallo de lectura concreto.
final Object? decoded;
try {
  decoded = jsonDecode(raw);
} on FormatException {
  return const InvalidSaveData();
}

return parseSaveData(decoded);
```

Si todas las salidas restauran lo mismo, hazlo una vez en `finally`.

```dart
Future<void> save() async {
  isSaving = true;
  try {
    await repository.save(party);
  } finally {
    isSaving = false;
  }
}
```

Nada de `return` ni `throw` dentro del `finally`: ocultarían el resultado o la
excepción del `try`.

## 4. La forma que menos hay que descifrar

- Para mapear un conjunto cerrado de valores, `switch` como expresión y exhaustivo.
- Ternarios entre dos valores simples, nunca anidados.
- `?.`, `??` y `??=` cuando expresen mejor el caso nulo.
- `if` y `for` dentro de colecciones para listas de widgets.
- Si una cadena de `where/map/fold` cuesta seguirla, usa un `for` con nombres claros.

```dart
// Mal
final children = <Widget>[];
if (canEdit) {
  children.add(const EditButton());
}

// Bien
final children = [
  if (canEdit) const EditButton(),
];
```

## 5. Condiciones con nombre

Una condición compuesta merece nombre si explica la decisión.

```dart
final canJoinParty =
    creature.isAlive && !creature.isAssigned && party.hasFreeSlot;
if (canJoinParty) {
  party.add(creature);
}
```

- Booleanos en positivo: `isValid`, no `isNotValid`. Evita dobles negaciones.
- Si la condición usa solo datos de un objeto, suele encajar como getter suyo.
- No escondas reglas del dominio bajo nombres de eventos de interfaz.

## 6. El código va en la clase que tiene los datos

Cada cálculo pertenece a quien tiene la información (Information Expert).
La vista debe leer una intención en vez de reconstruir la regla.

```dart
// Mal: cada pantalla vuelve a calcularlo.
final isDefeated = creature.health <= 0;

// Bien: en el modelo de dominio.
bool get isDefeated => health <= 0;
```

- El dominio no importa Flutter ni sabe de colores, iconos o diálogos.
- Las etiquetas y la traducción para pintar pertenecen a presentación.
  El dominio puede comunicar un motivo de fallo tipado sin texto de interfaz.
- Evita cajones de sastre nuevos como `Utils` o `Helper` genéricos.

## 7. Orden y formato del fichero

- Primero lo público. Dentro de una clase: campos, constructor y métodos.
- Procura que los métodos auxiliares estén después de quienes los usan.
- Separa guardas, preparación, acción y resultado con una línea en blanco.
- Divide una línea si mezcla llamada, transformación y decisión difíciles de seguir.
- Usa la versión del SDK fijada en `.fvmrc`: `fvm dart format <rutas>`.
  Revisa `fvm dart fix --dry-run` antes de aplicar correcciones automáticas.
- Usa imports directos y consistentes con el fichero. Si existe un barril mantenido
  en un paquete, reutilízalo; no crees `_imports.dart` por obligación.
- Deja que el formateador decida las comas finales según la versión de lenguaje.

## 8. Comentarios que explican el porqué

El código dice qué; el comentario explica por qué. Escribe los comentarios en español.

```dart
// Mal
// Elimina la última sala.
final completedRooms = rooms.sublist(0, rooms.length - 1);

// Bien
// La sala actual aún puede cambiar; el resumen solo cuenta las completadas.
final completedRooms = rooms.sublist(0, rooms.length - 1);
```

- Usa `///` en APIs públicas cuando ayude a explicar el contrato y sus casos límite.
- Documenta si un fallo devuelve `null`, `false`, un resultado tipado o una excepción.
- Si un comentario solo explica qué hace un bloque difícil de seguir, considera
  extraer un método con ese nombre.

## Repaso rápido

- Guardas arriba y camino normal con poca sangría.
- Restauración compartida en `finally`.
- Condiciones con nombre y cálculos en su capa.
- Llaves, imports y formato coherentes con el proyecto.
- Comentarios que explican decisiones.
