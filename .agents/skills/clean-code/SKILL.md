---
name: clean-code
description: Principios de código limpio para Dart/Flutter, alineados con Effective Dart. Cubre nombres, funciones pequeñas, duplicación, errores, Futures y Streams, mutabilidad, tipos y testabilidad. Úsala al escribir, refactorizar o revisar código, o cuando se pida limpiar o simplificar algo.
---

# Código limpio

El código debe hacer lo que parece que hace y poder cambiarse sin miedo.
Si una regla empeora un caso concreto, gana la claridad.

Respeta las instrucciones del usuario, el código real y `analysis_options.yaml`.
Los documentos `resources/documentation/generador_arquitectura_*.md` son plantillas
adaptables; no obligan a crear capas ni dependencias que la funcionalidad no necesita.
En cuestiones de estilo, sigue el fichero que tocas y los lints activos.

Complementa a `readable-code` (flujo y formato), `solid-principles` (responsabilidades)
y `flutter-ui` (páginas y widgets). Los ejemplos de juego son ilustrativos.

## 1. Nombres

- Identificadores en inglés: `UpperCamelCase` para tipos, `lowerCamelCase` para miembros
  y constantes, `snake_case` para ficheros y paquetes.
- Clases con sustantivos, métodos con verbos y booleanos con `is/has/can/should`.
- Usa el vocabulario del dominio y los nombres ya presentes. No inventes sinónimos
  para una misma operación.
- La unidad va en el tipo o en el nombre: `Duration` antes que `int`;
  `timeoutMs` si se necesita una cantidad numérica.
- En lambdas pequeñas valen nombres cortos como `m`. Campos, parámetros con nombre
  y variables de métodos largos necesitan nombres completos; `id` y `url` son válidos.

```dart
// Mal
final l = party.get2(true);
int time = 3;

// Bien
final injuredMembers = party.injuredMembers;
const turnDelay = Duration(seconds: 3);
```

## 2. Funciones

- Una responsabilidad y un nivel de abstracción. Separa tareas que cambian por
  motivos distintos.
- No extraigas funciones minúsculas de un solo uso solo para envolver una llamada.
  Extrae cuando haya reutilización o el cuerpo dificulte entender al llamador.
- Con más de dos parámetros, usa parámetros con nombre.
- Evita booleanos que cambian el comportamiento: dos métodos o un `enum` suelen
  expresar mejor la intención. Si hay un booleano, que tenga nombre.
- Las consultas y getters no cambian el estado. Las mutaciones se llaman
  `save`, `remove`, `clear` o con otro verbo que explique el cambio.

## 3. Duplicación

Una regla de negocio, fórmula o constante vive en un solo sitio. Si cambiar una
copia obliga a cambiar otra, comparte la implementación desde la segunda copia.

- Busca primero modelos, extensiones y widgets existentes en `lib/` y en las
  dependencias declaradas.
- Las reglas del juego pertenecen al dominio. Los widgets reutilizables van junto a
  su funcionalidad o en una carpeta compartida cuando los necesitan varias.
- Una función sobre un tipo suele encajar como método o extensión de ese tipo;
  evita crear `Utils` o `Helper` genéricos.

## 4. Valores y textos

- Da nombre a los límites y constantes de negocio. No conviertas cada medida trivial
  de layout en una constante independiente; comparte las medidas recurrentes.
- Un conjunto cerrado de valores es un `enum`. Evita booleanos que permitan estados
  contradictorios.
- Usa el mecanismo de localización existente para los textos visibles. Si aún no
  existe, centraliza los textos nuevos y plantea una solución proporcional;
  no presupongas paquetes ni funciones de traducción.
- Colores, iconos y etiquetas para pintar pertenecen a presentación.

```dart
// Mal: el número no explica el estado.
if (creature.status == 3) return false;

// Bien: ejemplo de un estado tipado.
if (creature.status == CreatureStatus.exhausted) {
  return false;
}
```

## 5. Errores

- No añadas `try/catch` por precaución en cada pantalla. Gestiona los fallos esperados
  en la capa responsable de la operación y deja que los errores de programación salgan.
- Si existe un contrato de resultado tipado, úsalo y comprueba el resultado.
  Para una ausencia esperada, `null` o una colección vacía pueden ser suficientes.
- No inventes una clase `Result` para envolver cada operación trivial.
- Captura excepciones concretas y solo la llamada que puede fallar.
- Nunca `catch (_) {}`. Decide cómo informar o recuperar el fallo sin ocultarlo.
- Usa `try/finally` para restaurar estado o liberar recursos aunque algo falle.
- Documenta cómo falla una API pública cuando ese comportamiento no sea obvio.

## 6. Futures y Streams

- Una función `async` devuelve `Future<T>`, nunca `void`.
- Espera los Futures de los que depende el resultado. Una tarea que se lanza en
  segundo plano debe tener un motivo y una forma de gestionar sus errores.
- Dentro de un `try`, `return await` si el `catch` debe recibir el error asíncrono.
- Cancela suscripciones y cierra los controladores que posees al liberar su dueño.
- Tras un `await`, comprueba `mounted` antes de usar el contexto de un widget.
- No bloquees el arranque con datos que pueden cargarse después. Reutiliza el estado
  o los streams existentes en vez de repetir cargas o sincronizaciones.

```dart
// Mal: la pantalla anuncia éxito antes de guardar.
void onSave() async {
  repository.save(party);
  isSaved = true;
}

// Bien: ejemplo con un contrato que devuelve bool.
Future<void> onSave() async {
  isSaved = await repository.save(party);
}
```

## 7. Mutabilidad

- `final` por defecto en campos y variables locales.
- Los estados de pantalla deben cambiar de forma controlada; si la solución usa
  estados inmutables, conserva ese contrato y su mecanismo de copia.
- Los modelos solo tienen setters cuando el comportamiento o un contrato real lo
  requiere. No añadas campos de sincronización a una entidad que no los necesita.
- Mantén el estado mutable privado y en el menor alcance posible.

## 8. Tipos

- `dynamic` solo en bordes externos, como JSON, y convertido a tipos antes de salir
  del adaptador.
- Declara los tipos de retorno. Omite tipos locales cuando la inferencia sea clara.
- No uses `!` para callar al analizador. Trata la ausencia o copia a una variable local
  para que Dart pueda promover el tipo.

```dart
// Mal
if (selectedCreature != null) {
  title = selectedCreature!.name;
}

// Bien
final creature = selectedCreature;
if (creature != null) {
  title = creature.name;
}
```

## 9. Simplicidad

- Borra código muerto y bloques comentados; Git conserva el historial.
- Usa el sistema de registro existente. No dejes `print` de depuración.
- Un `TODO` explica qué falta y por qué.
- KISS y YAGNI: no añadas capas, parámetros, paquetes ni interfaces por anticipación.

## 10. Testabilidad

- La lógica pura del juego vive fuera de widgets y de E/S.
- Inyecta lo que cambia entre ejecución y tests: repositorios, generadores aleatorios,
  reloj o funciones concretas. Una función basta para una sola operación.
- Los tests comprueban comportamientos y casos límite, sin depender de la red,
  la fecha actual o el orden de ejecución.
- Reutiliza los fakes existentes o crea los mínimos necesarios para el comportamiento.

```dart
// Mal: el resultado depende de cuándo se ejecute.
bool get isExpired => DateTime.now().isAfter(expiry);

// Bien
bool isExpiredAt(DateTime now) => now.isAfter(expiry);
```

## Repaso rápido

- Nombres claros, funciones cohesionadas y reglas sin duplicación.
- Fallos esperados tratados en su capa y operaciones asíncronas ordenadas.
- Recursos liberados, datos tipados y mutabilidad controlada.
- Lógica comprobable sin Flutter, red ni reloj real.
