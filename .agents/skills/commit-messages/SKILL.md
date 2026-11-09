---
name: commit-messages
description: Redacta mensajes de commit en español siguiendo Conventional Commits con gitmoji, usando como scope la aplicación afectada. Úsala para proponer el mensaje a partir de los cambios en stage; solo redacta el mensaje, nunca hace el commit.
---

# Mensajes de commit

**Esta skill solo redacta el mensaje; el commit lo hace el usuario.** No ejecutes
`git commit`, `git add`, `git restore --staged`, `git reset` ni ningún otro comando que
cambie el stage o el historial, aunque la petición diga «haz», «añade» o «crea» un commit.
Muestra el mensaje en un bloque de código listo para copiar.

## Formato

```
<tipo>(<app>): :<gitmoji>: <descripción>

<cuerpo opcional>

<pie opcional>
```

```
fix(Dungeon Crawler 0): :bug: Corregida selección de criatura
```

- **Idioma:** descripción, cuerpo y pie en español. El tipo, el código del gitmoji y los
  nombres de clases, métodos o ficheros se escriben tal cual.
- **Una línea de asunto** de unos 72 caracteres como máximo, sin punto final. Empieza en
  mayúscula y con participio, como el historial: «Añadido…», «Corregido…», «Eliminado…».
- **Cuerpo** separado por una línea en blanco y ajustado a unas 72 columnas. Explica qué
  cambia y por qué, no cómo (eso ya lo muestra el diff). Si hay varios cambios, un punto
  `- ` por cada uno, con una línea en blanco entre puntos.
- **Pie** separado por una línea en blanco, con formato `Clave: valor`:
  `Refs: DC0-42`, `BREAKING CHANGE: …`, `Co-Authored-By: …`.

## Pasos

1. Lee `git diff --staged` (o `git diff` si no hay nada en stage) y `git log -5` para ver
   el contexto.
2. Si hay cambios sin relación entre sí, propón separarlos en varios commits: un commit,
   un propósito. Indica qué ficheros van en cada uno y redacta un mensaje por commit, pero
   no toques el stage.
3. Elige el tipo por el cambio principal y el gitmoji que mejor lo concrete.
4. Elige la app (scope).
5. Escribe el asunto pensando en quien lea `git log --oneline` dentro de un año: qué
   cambia para el usuario o para el código, no «Cambios» ni «Ajustes del merge anterior».
   Si el commit sigue a un merge, nombra lo que se ajusta y añade su ticket en el pie.
6. Entrega el mensaje en un bloque de código y termina ahí: sin `git commit`.

## Tipos

| Tipo       | Cuándo                                              | Gitmoji habitual           |
|------------|-----------------------------------------------------|----------------------------|
| `feat`     | Funcionalidad nueva o cambio visible para el usuario | `:sparkles:`, `:lipstick:` |
| `fix`      | Corrección de un error                              | `:bug:`, `:ambulance:`     |
| `refactor` | Cambio interno sin alterar el comportamiento        | `:recycle:`                |
| `perf`     | Mejora de rendimiento                               | `:zap:`                    |
| `style`    | Formato, sin cambio de lógica                       | `:art:`                    |
| `test`     | Tests nuevos o actualizados                         | `:white_check_mark:`       |
| `docs`     | Documentación, README, skills                       | `:memo:`                   |
| `build`    | Dependencias, compilación, empaquetado              | `:arrow_up:`, `:package:`  |
| `ci`       | Integración continua                                | `:construction_worker:`    |
| `chore`    | Mantenimiento que no encaja en lo anterior          | `:wrench:`, `:fire:`       |
| `revert`   | Deshace un commit anterior                          | `:rewind:`                 |

Un cambio que rompe una API pública lleva `!` tras el scope, `:boom:` y el pie
`BREAKING CHANGE:` explicando qué deben cambiar sus consumidores:

```
refactor(Dungeon Crawler 0)!: :boom: Renombrado Monster a Creature

BREAKING CHANGE: los consumidores deben usar Creature en lugar de Monster.
```

## Scope: la aplicación

En este repositorio usa `Dungeon Crawler 0` como scope de la aplicación.
Si esta skill se reutiliza en otro proyecto, usa el nombre de esa aplicación.

- Si el cambio afecta al juego, usa su scope.
- Si se reutiliza en un repositorio con cambios transversales a varias apps, omite el scope:
  `fix: :bug: …`.

## Gitmojis

- **Funcionalidad:** `:sparkles:` nueva funcionalidad · `:necktie:` lógica de negocio ·
  `:passport_control:` permisos y roles · `:safety_vest:` validaciones · `:airplane:` modo
  sin conexión · `:triangular_flag_on_post:` feature flags · `:card_file_box:` base de datos
  · `:seedling:` datos semilla · `:label:` tipos · `:thread:` concurrencia · `:alien:`
  adaptación a una API externa · `:chart_with_upwards_trend:` analítica · `:mag:` SEO ·
  `:stethoscope:` healthcheck · `:money_with_wings:` pagos o patrocinios · `:egg:` easter egg
- **UI:** `:lipstick:` interfaz y estilos · `:dizzy:` animaciones · `:iphone:` diseño
  responsive · `:children_crossing:` usabilidad · `:wheelchair:` accesibilidad ·
  `:speech_balloon:` textos y literales · `:globe_with_meridians:` traducciones · `:bento:`
  assets
- **Correcciones:** `:bug:` error · `:ambulance:` hotfix crítico · `:adhesive_bandage:`
  arreglo simple no crítico · `:lock:` seguridad o privacidad · `:goal_net:` captura de
  errores · `:rotating_light:` avisos del compilador o linter · `:pencil2:` erratas ·
  `:green_heart:` arreglar la CI
- **Código:** `:recycle:` refactorización · `:art:` estructura o formato · `:zap:`
  rendimiento · `:building_construction:` arquitectura · `:truck:` mover o renombrar
  ficheros y rutas · `:fire:` eliminar código o ficheros · `:coffin:` código muerto ·
  `:wastebasket:` marcar como obsoleto · `:bulb:` comentarios en el código · `:loud_sound:`
  añadir logs · `:mute:` quitar logs · `:technologist:` experiencia de desarrollo ·
  `:construction:` trabajo en curso · `:alembic:` experimento · `:monocle_face:`
  exploración de datos · `:poop:` código que hay que mejorar · `:beers:` código escrito
  sin pensar
- **Tests:** `:white_check_mark:` añadir, actualizar o pasar tests · `:test_tube:` test que
  falla · `:clown_face:` mocks · `:camera_flash:` snapshots
- **Dependencias y build:** `:heavy_plus_sign:` añadir dependencia · `:heavy_minus_sign:`
  quitar dependencia · `:arrow_up:` subir versión · `:arrow_down:` bajar versión ·
  `:pushpin:` fijar versión · `:package:` ficheros compilados o paquetes · `:wrench:`
  configuración · `:hammer:` scripts de desarrollo · `:see_no_evil:` `.gitignore` ·
  `:closed_lock_with_key:` secretos · `:construction_worker:` sistema de CI · `:bricks:`
  infraestructura
- **Proyecto y versiones:** `:tada:` inicio de proyecto · `:bookmark:` versión o tag ·
  `:rocket:` despliegue · `:rewind:` revertir · `:twisted_rightwards_arrows:` merge de ramas
  · `:boom:` cambio incompatible · `:memo:` documentación · `:page_facing_up:` licencia ·
  `:busts_in_silhouette:` contribuidores

## Ejemplos

```
// Mal
fix: :bug: Cambios.
refactor: :recycle: Refactorizaciones merge anterior.
feat(Dungeon Crawler 0): :sparkles: Added party management

// Bien
fix(Dungeon Crawler 0): :bug: Corregida selección de criatura
test(Dungeon Crawler 0): :white_check_mark: Añadidos tests de combate
feat(Dungeon Crawler 0): :sparkles: Añadida gestión del grupo

- Grupo: selección y reordenación de sus integrantes.

- Criaturas: consulta de sus estadísticas desde el grupo.

Refs: DC0-42
```
