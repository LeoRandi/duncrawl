---
name: solid-principles
description: Aplica SOLID al diseño Dart/Flutter, separando dominio, datos, composición y presentación. Úsala al crear clases o paquetes, decidir dónde va una responsabilidad o si hace falta una abstracción, y al revisar o refactorizar el diseño.
---

# SOLID en Dart/Flutter

SOLID sirve para que un cambio toque pocas clases. No crees interfaces ni capas
que no resuelvan un problema real.

Respeta las instrucciones del usuario, el código real y `analysis_options.yaml`.
Los documentos `resources/documentation/generador_arquitectura_*.md` son plantillas
adaptables; no obligan a crear capas ni dependencias que la funcionalidad no necesita.
En cuestiones de estilo, sigue el fichero que tocas y los lints activos.

Complementa a `clean-code` (simplicidad y testabilidad), `readable-code` (flujo y
ubicación de cálculos) y `flutter-ui` (presentación). Los ejemplos son ilustrativos.

## S: Responsabilidad única

Una clase, un motivo para cambiar. Estos nombres describen responsabilidades;
no exigen un paquete independiente por fila.

| Capa | Pieza posible | Responsabilidad |
|---|---|---|
| Dominio | `XxxModel` o nombre de entidad | Datos y reglas que dependen de ellos. |
| Dominio | `XxxUseCase`, `XxxRule` | Acciones y reglas que coordinan entidades. |
| Dominio | `XxxRepository` o `XxxRepositoryBase` | Contrato de datos que necesita el dominio. |
| Datos | Implementación del repositorio | Coordinar las fuentes necesarias. |
| Datos | `XxxLocal`, adaptador | Persistencia y conversión del almacenamiento. |
| Datos | `XxxRemote`, DTO | Red y conversión de JSON, solo si existe backend. |
| Composición | Factoría o inyector | Construir las dependencias concretas. |
| Presentación | Page, Screen, Provider o ViewModel | Estado de pantalla y acciones de interfaz. |
| Presentación | Widgets y extensiones | Layout, textos, colores e iconos. |

Las reglas del juego van en dominio aunque hoy solo las use una pantalla.
Una validación necesaria para ejecutar una acción se aplica también fuera de la UI.

```dart
// Mal: la pantalla decide una regla que otras entradas pueden saltarse.
onPressed: () {
  if (party.members.length < maximumPartySize) {
    party.members.add(creature);
  }
};

// Bien: ejemplo con una operación de dominio que valida el límite.
onPressed: () => controller.recruit(creature);
```

El controlador llama a la operación del dominio y traduce su resultado a estado de
pantalla. Si el formulario anticipa una validación, reutiliza esa misma regla.

Señales de mezcla: un widget que llama al almacenamiento, un modelo que importa
`flutter/material.dart` o una regla del juego escrita solo en un callback.
Responsabilidad única no significa un método por clase.

## O: Abierto/cerrado

Añade comportamiento sin duplicar lo que ya funciona, con la solución más sencilla
que permita el cambio.

- Reutiliza las extensiones o contratos existentes cuando sus invariantes encajen.
  No introduzcas una jerarquía solo para evitar un `switch` claro.
- Para conjuntos cerrados, usa `enum` y `switch` exhaustivo sin `default`. Mantén
  colores y etiquetas en presentación.
- Si hay red, concentra HTTP y serialización en la fuente remota. Las pantallas no
  construyen peticiones. Respeta el cliente y la política de rutas elegidos.
- Usa imports condicionales cuando `dart:io` o las APIs web impidan compilar en otra
  plataforma; `kIsWeb` sirve para decisiones que ambas plataformas pueden compilar.

```dart
// Ejemplo de conjunto cerrado.
enum DamageType { physical, fire, ice }

double resistanceFor(DamageType type) => switch (type) {
  DamageType.physical => physicalResistance,
  DamageType.fire => fireResistance,
  DamageType.ice => iceResistance,
};
```

## L: Sustitución de Liskov

Cada implementación debe respetar el contrato que usa su consumidor.

- Si el contrato promete `null` cuando falta un dato, no lances en ese caso.
- No exijas precondiciones adicionales ni reduzcas las garantías de la interfaz.
- Evita `UnimplementedError` en producción: suele indicar que el contrato obliga a
  depender de operaciones que no corresponden.
- Los fakes deben conservar la semántica relevante, incluidos fallos y ausencias.

```dart
// Contrato de ejemplo: la ausencia es normal.
abstract interface class CreatureRepository {
  Future<Creature?> getById(String id);
}

// Una implementación respeta la ausencia sin convertirla en excepción.
Future<Creature?> getById(String id) async => creaturesById[id];
```

## I: Segregación de interfaces

Nadie debería depender de operaciones que no usa.

- Diseña contratos pequeños alrededor de una necesidad real. No añadas CRUD,
  sincronización o borrado si el consumidor no los necesita.
- Para una sola operación, una función suele bastar:
  `DateTime Function()` evita una interfaz de reloj innecesaria.
- Los widgets hoja reciben los datos y callbacks que necesitan. Una página puede
  recibir su controlador cuando coordina la pantalla completa.

```dart
// Mal: el componente depende de toda la pantalla.
const HealthBar({required this.controller});

// Bien: solo depende de lo que presenta.
const HealthBar({required this.health, required this.maximumHealth});
```

## D: Inversión de dependencias

El dominio y la coordinación dependen de contratos; los detalles de almacenamiento,
red o plugins los implementan.

- La abstracción pertenece al consumidor: un contrato de repositorio usado por el
  dominio vive en dominio.
- Recibe dependencias por constructor en vez de construirlas en los casos de uso.
- Construye las piezas concretas en la composición de la app. No es obligatorio
  añadir un contenedor de inyección; los constructores suelen bastar al empezar.
- Usa el mecanismo ya presente si existe. Evita localizadores globales nuevos.

```dart
// Mal: la regla queda atada a un almacenamiento concreto.
class RecruitCreature {
  final repository = FileCreatureRepository();
}

// Bien: ejemplo con una dependencia sustituible.
class RecruitCreature {
  final CreatureRepository repository;

  RecruitCreature(this.repository);
}
```

## Cuándo no añadir abstracciones

- Una clase interna cohesionada y sin necesidad de sustitución no necesita `XxxBase`.
- Antes de dividir una clase larga, comprueba si bastan métodos o widgets pequeños.
- No crees cinco paquetes para una entidad solo porque una plantilla los enumere.
- No fijes motor de juego, gestión de estado o persistencia sin una necesidad concreta.

## Repaso rápido

- Reglas del juego en dominio; presentación y datos con sus propios motivos de cambio.
- Contratos pequeños, sustituibles y recibidos por constructor.
- Sin métodos vacíos, dependencias globales ni jerarquías preventivas.
