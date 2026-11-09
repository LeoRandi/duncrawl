# Plantilla para diseñar una entidad Dart/Flutter

Usa esta plantilla cuando se pida crear una entidad o adaptar datos JSON.
No implica que las clases del ejemplo estén implementadas ni que haya un backend.

## Datos de entrada

Proporciona el nombre de la entidad, los campos o un JSON de ejemplo, las operaciones
necesarias y las reglas conocidas. Si una regla no está definida, no la inventes.

Ejemplo ilustrativo para Dungeon Crawler 0:

```json
{
  "id": "creature-1",
  "name": "Slime"
}
```

## Petición reutilizable

Adapta la entidad a las convenciones del repositorio:

1. Revisa `pubspec.yaml`, `analysis_options.yaml`, `.fvmrc` y el código existente.
2. Usa identificadores en inglés y comentarios en español. Conserva las claves JSON
   que exija el formato externo.
3. Mantén los modelos y las reglas en Dart puro, sin Flutter ni almacenamiento.
4. Añade un contrato de repositorio solo si la operación necesita datos.
5. Implementa únicamente las fuentes necesarias: local para almacenamiento,
   remota si existe backend. La conversión de JSON pertenece al adaptador de datos.
6. Recibe dependencias por constructor y construye las piezas concretas en la app.
7. Separa estado y acciones de pantalla de sus widgets. Reutiliza las reglas del
   dominio para anticipar validaciones.
8. No añadas paquetes, sincronización, permisos, campos de auditoría ni generación
   de código sin una necesidad explícita.
9. Formatea los ficheros modificados con el SDK fijado y comprueba los comportamientos
   relevantes para la nueva lógica.

## Responsabilidades

| Pieza | Responsabilidad |
|---|---|
| Modelo | Datos e invariantes de la entidad. |
| Regla o caso de uso | Validar y ejecutar una acción del dominio. |
| Contrato de repositorio | Describir los datos que necesita su consumidor. |
| Repositorio y fuentes | Leer, guardar y convertir formatos externos. |
| Composición | Construir e inyectar las dependencias. |
| Presentación | Estado de pantalla, textos, layout y acciones de interfaz. |

Estas responsabilidades pueden vivir en una funcionalidad dentro de `lib/`.
No es obligatorio crear paquetes independientes ni una clase por cada fila.

El ejemplo con rutas y código está en
[generador_arquitectura_agente_ia.md](generador_arquitectura_agente_ia.md).
