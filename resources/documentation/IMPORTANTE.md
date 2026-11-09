# Notas importantes de Dart/Flutter

Estas notas son independientes de servicios o aplicaciones externos. Las decisiones
del juego y las convenciones vigentes se comprueban en el código y las skills locales.

## Identificadores de entidades

Usa una identidad estable para relacionar datos y conservar partidas.
No presupongas que el identificador de una entidad sea siempre un entero ni que su
nombre visible sea único. Si se integra un formato externo, documenta su clave real.

## Objetos y parámetros

Dart pasa los valores de los argumentos por valor. Para un objeto, ese valor permite
acceder a la misma instancia: modificar sus campos afecta a sus otros consumidores.
Reasignar el parámetro cambia solo la variable local.

```dart
class Counter {
  int value;

  Counter(this.value);
}

void replaceCounter(Counter counter) {
  counter = Counter(counter.value + 1);
}

void incrementCounter(Counter counter) {
  counter.value++;
}

Counter incrementedCopy(Counter counter) => Counter(counter.value + 1);

void main() {
  var counter = Counter(1);

  replaceCounter(counter);
  assert(counter.value == 1);

  incrementCounter(counter);
  assert(counter.value == 2);

  counter = incrementedCopy(counter);
  assert(counter.value == 3);
}
```

Para modelos inmutables, devuelve una copia y actualiza explícitamente el estado
propietario. No dependas de efectos secundarios de una expresión para cambiar datos.

## Callbacks que usan datos antiguos

Una clausura puede conservar una referencia o un valor de una construcción anterior.
Si aparecen datos antiguos después de actualizar el estado:

- Comprueba dónde se creó el callback y qué valor capturó.
- Cancela suscripciones antiguas y libera controladores al cerrar su dueño.
- Reconstruye la vista o actualiza su fuente de estado cuando cambie el dato.
- Usa identificadores y claves estables en listas que se reordenan.

No introduzcas un acceso global para ocultar un callback o una suscripción obsoletos.
