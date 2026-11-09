# Generación de una entidad con rutas y capas

Esta guía ofrece un ejemplo independiente de paquetes privados. Las clases son
ilustrativas: no forman parte del código actual ni fijan las mecánicas del juego.
La app conserva su estructura inicial hasta que una funcionalidad necesite ampliarla.

## Antes de generar

- Revisa las skills locales, `pubspec.yaml`, `analysis_options.yaml` y el código real.
- Aclara qué datos, operaciones y reglas requiere la funcionalidad.
- Escribe identificadores en inglés y comentarios en español.
- Mantén las reglas en Dart puro y los detalles de Flutter en presentación.
- Usa dependencias declaradas. No añadas almacenamiento, red o sincronización
  solo porque una plantilla anterior tuviese esas capas.
- Las claves JSON siguen el formato externo; los nombres Dart siguen el dominio.

## Organización orientativa

Para una entidad con persistencia y UI, las responsabilidades pueden organizarse así:

```text
lib/
  features/
    creature/
      domain/
        creature.dart
        creature_name_rule.dart
        creature_repository.dart
        rename_creature.dart
      data/
        creature_codec.dart
        memory_creature_repository.dart
      presentation/
        creature_page.dart
        creature_controller.dart
  app/
    app_dependencies.dart
```

Crea solo los ficheros necesarios. En una funcionalidad pequeña, algunos pueden
compartir fichero. Si una capa necesita reutilizarse de forma independiente, se puede
extraer a un paquete con su `pubspec.yaml`.

La separación clásica entre `domain`, `repository`, `local`, `injector` y `view`
describe responsabilidades, no una obligación de crear cinco paquetes:
`data` agrupa repositorio y fuentes; la composición hace de inyector y
`presentation` contiene la vista.

## 1. Modelo de dominio

Ruta orientativa: `lib/features/creature/domain/creature.dart`.

```dart
class Creature {
  final String id;
  final String name;

  const Creature({required this.id, required this.name});

  Creature copyWith({String? name}) =>
      Creature(id: id, name: name ?? this.name);
}
```

Añade campos y mutabilidad solo cuando el comportamiento lo requiera.
Identificadores, borrado lógico y metadatos de sincronización no se presuponen.

## 2. Regla compartida

Ruta orientativa: `lib/features/creature/domain/creature_name_rule.dart`.

Esta validación es una regla de ejemplo. Sustitúyela por los requisitos del juego.

```dart
enum CreatureNameProblem { empty }

CreatureNameProblem? validateCreatureName(String name) {
  if (name.trim().isEmpty) {
    return CreatureNameProblem.empty;
  }

  return null;
}
```

El dominio devuelve un motivo tipado. Presentación decide qué texto y traducción
mostrar; no se introduce una dependencia de localización en el modelo.

## 3. Contrato del repositorio

Ruta orientativa: `lib/features/creature/domain/creature_repository.dart`.

```dart
import 'creature.dart';

abstract interface class CreatureRepository {
  /// Devuelve null si la criatura no existe.
  Future<Creature?> getById(String id);

  /// Guarda la criatura; los fallos de almacenamiento se propagan.
  Future<void> save(Creature creature);
}
```

El contrato incluye solo lo que necesita el consumidor. Si se requieren fallos
recuperables tipados, define ese contrato antes de implementar fuentes y consumidores.

## 4. Caso de uso

Ruta orientativa: `lib/features/creature/domain/rename_creature.dart`.

```dart
import 'creature.dart';
import 'creature_name_rule.dart';
import 'creature_repository.dart';

enum RenameCreatureResult { saved, invalidName, notFound }

class RenameCreature {
  final CreatureRepository repository;

  RenameCreature(this.repository);

  /// Comunica las validaciones esperadas; propaga fallos de almacenamiento.
  Future<RenameCreatureResult> execute({
    required String creatureId,
    required String name,
  }) async {
    if (validateCreatureName(name) != null) {
      return RenameCreatureResult.invalidName;
    }

    final Creature? creature = await repository.getById(creatureId);
    if (creature == null) {
      return RenameCreatureResult.notFound;
    }

    await repository.save(creature.copyWith(name: name.trim()));
    return RenameCreatureResult.saved;
  }
}
```

La vista puede anticipar `validateCreatureName`, pero el caso de uso vuelve a aplicar
la misma regla para que ninguna entrada se la salte.

## 5. Fuente en memoria

Ruta orientativa: `lib/features/creature/data/memory_creature_repository.dart`.

```dart
import '../domain/creature.dart';
import '../domain/creature_repository.dart';

class MemoryCreatureRepository implements CreatureRepository {
  final Map<String, Creature> _creatures;

  MemoryCreatureRepository(Iterable<Creature> creatures)
      : _creatures = {for (final creature in creatures) creature.id: creature};

  @override
  Future<Creature?> getById(String id) async => _creatures[id];

  @override
  Future<void> save(Creature creature) async {
    _creatures[creature.id] = creature;
  }
}
```

Una implementación en memoria permite probar el caso de uso. No guarda entre sesiones.
Añade una fuente persistente únicamente cuando la funcionalidad lo necesite.

## 6. Conversión de JSON

Ruta orientativa: `lib/features/creature/data/creature_codec.dart`.
Úsala solo si existe un formato JSON que leer o escribir.

```dart
import '../domain/creature.dart';

class CreatureCodec {
  /// Lanza FormatException si faltan campos o tienen tipos incorrectos.
  static Creature fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      throw const FormatException('Invalid creature data');
    }

    return Creature(id: id, name: name);
  }

  static Map<String, Object?> toJson(Creature creature) => {
    'id': creature.id,
    'name': creature.name,
  };
}
```

Valida datos externos en el adaptador. La fuente responsable decide cómo gestionar
datos corruptos; un mensaje técnico de excepción no se muestra directamente al usuario.

Si se usa una base de datos, documenta sus migraciones y conserva la compatibilidad
del formato de guardado. No presupongas Hive, SQLite ni un backend concreto.

## 7. Composición

La app crea la implementación concreta e inyecta el contrato. Ejemplo de cuerpo de
una factoría, con imports de los ficheros anteriores:

```dart
final repository = MemoryCreatureRepository(initialCreatures);
final renameCreature = RenameCreature(repository);
```

Un contenedor de inyección es opcional. No obtengas repositorios desde globales nuevos
en los modelos o casos de uso.

## 8. Presentación

Cuando se necesite una pantalla:

- `CreaturePage` recibe sus datos, acciones o controlador por constructor.
- El controlador ejecuta el caso de uso y mantiene el estado de carga y resultado.
- El formulario complejo tiene valores y validaciones comprobables en Dart puro.
- El widget solo dibuja y delega acciones; traduce los motivos de dominio.
- Los controladores Flutter y suscripciones tienen dueño y se liberan al cerrarlo.
- Usa componentes de la app si existen y controles Flutter si no.
- No se presupone una biblioteca de estado ni un sistema de ventanas.

Consulta `.agents/skills/flutter-ui/SKILL.md` para ciclo de vida, accesibilidad y listas.

## Comprobaciones al generar código

Con FVM, desde la raíz del proyecto:

```powershell
fvm dart format <rutas_modificadas>
fvm flutter analyze
fvm flutter test
```

Sustituye el marcador por las rutas reales. Ejecuta las pruebas adecuadas al cambio.
Para la entidad del ejemplo, serían relevantes nombre vacío, criatura ausente,
guardado correcto y lectura de JSON inválido. No necesitas generar UI para probar
esas reglas.
