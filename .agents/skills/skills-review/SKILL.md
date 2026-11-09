---
name: skills-review
description: Revisa las skills locales frente al código real, los lints y las plantillas de arquitectura, comprobando coherencia, referencias y utilidad. Devuelve APROBADO o cambios con evidencia. Úsala al crear o modificar una skill, idealmente en un subagente y en bucle hasta que apruebe.
---

# Revisión de skills

Revisa `.agents/skills/*/SKILL.md` sin editarlas: lee, comprueba y critica.
Si se ejecuta en un subagente, quien lo lanza aplica las correcciones y pide otra
revisión hasta que salga APROBADO.

## Fuentes de verdad, por prioridad

1. Instrucciones y alcance autorizados por el usuario.
2. Código real, dependencias de `pubspec.yaml`, SDK de `.fvmrc` y
   `analysis_options.yaml`. Considera las reglas heredadas del `include`:
   `analyzer.errors` solo cambia severidades, no activa un lint por sí mismo.
3. Plantillas `resources/documentation/generador_arquitectura_chatgpt.md` y
   `generador_arquitectura_agente_ia.md`. Son referencias adaptables, no prueba de
   que una clase o dependencia exista.
4. Effective Dart y Flutter. Consulta documentación oficial si hay dudas que el
   proyecto y el SDK local no resuelven.
5. Principios de diseño, solo donde aporten claridad y no contradigan lo anterior.

## Qué comprobar

1. **Referencias reales.** Busca en el repositorio excluyendo `build/`,
   `.dart_tool/` y SDKs locales. Las rutas y APIs operativas deben existir.
   Los ejemplos futuros deben identificarse como ilustrativos, sin afirmar que
   ya están implementados.
2. **Independencia.** Ninguna skill exige repositorios privados, rutas externas,
   paquetes ausentes, servicios o marcas ajenos al proyecto.
3. **Arquitectura proporcional.** Dominio sin Flutter; reglas compartidas entre
   validación y ejecución; presentación y datos separados. No se imponen capas,
   gestores de estado o paquetes de persistencia sin una necesidad real.
4. **SDK y lints.** No afirmes que un lint está desactivado sin comprobarlo.
   El estilo de los ejemplos debe respetar los lints activos.
5. **Ejemplos.** Deben ser Dart válido como fragmentos o estar marcados como
   esquemáticos. No deben ocultar supuestos ni copiar una regla en varias capas.
6. **Coherencia entre skills.** Cada regla vive en una sola skill y las demás la
   referencian. Las referencias cruzadas existen y las precedencias coinciden.
7. **Identidad y utilidad.** Conserva el propósito de cada skill, incluidos idioma,
   convenciones de commit y límites de actuación. Evita convertir preferencias
   o ejemplos aislados en obligaciones generales.
8. **Concisión y frontmatter.** `name` coincide con la carpeta; `description` explica
   cuándo usar la skill. Mantén unas 250 líneas como máximo y evita relleno.

## Formato de respuesta

```text
VEREDICTO: APROBADO | CAMBIOS

1. [bloqueante|importante|menor] skill/SKILL.md:línea — problema.
   Evidencia: fichero, comando o fuente que lo demuestra.
   Propuesta: cambio concreto.
```

- De más a menos grave, máximo 15 puntos, agrupando los parecidos.
- APROBADO solo si no queda nada bloqueante ni importante. Los menores son opcionales.
- En rondas posteriores, indica qué sigue abierto sin repetir lo resuelto.
- Cada crítica cita evidencia; una preferencia personal no basta.
