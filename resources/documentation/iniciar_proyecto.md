# Preparar el proyecto Flutter

Dungeon Crawler 0 es una app Flutter independiente. El nombre de paquete actual es
`duncrawl`. No requiere submódulos ni repositorios privados para empezar.

## SDK y dependencias

La versión del SDK está fijada en `.fvmrc`. Con FVM instalado, desde la raíz:

```powershell
fvm install
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter run
```

Usa el mismo SDK en el editor y en la terminal. Si ya está disponible mediante
`.fvm/flutter_sdk`, también puedes ejecutar sus binarios directamente.

## Estructura y convenciones

- Lee las skills de `.agents/skills/` antes de crear código.
- Conserva `analysis_options.yaml` y comprueba los lints activos antes de describirlos.
- Mantén las reglas del juego en Dart puro, separadas de widgets y E/S.
- Crea las carpetas y dependencias que necesite cada funcionalidad. Las plantillas
  `generador_arquitectura_*.md` muestran responsabilidades y ejemplos adaptables.

## Assets

Añade solo las carpetas de imágenes, audio y otros recursos que vayas a utilizar.
Declara sus rutas en `pubspec.yaml`; este bloque es ilustrativo:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/audio/
```

No declares carpetas que no existan. Mantén las licencias de los recursos externos.

## Textos y traducciones

Centraliza los textos visibles. Si se añade localización, usa la solución elegida
para la app y declara sus dependencias y archivos de generación.
No es necesario un repositorio externo de traducciones.

## Identidad de la aplicación

El título provisional es `Dungeon Crawler 0`. Al configurar la identidad:

- Android: revisa `android:label` en `android/app/src/main/AndroidManifest.xml`.
- iOS: revisa `CFBundleDisplayName` y `CFBundleName` en `ios/Runner/Info.plist`.
- Conserva `duncrawl` como nombre del paquete Dart salvo que se decida renombrarlo.
- Antes de publicar, elige los identificadores definitivos y revisa los iconos de
  lanzamiento de cada plataforma.

## Configuración Android e iOS

- Android usa actualmente `android/app/build.gradle.kts`. No pegues bloques Groovy
  en un fichero Kotlin DSL.
- Revisa mínimos de plataforma según los dispositivos objetivo y las dependencias
  reales. No copies números de SDK de otra app.
- Añade únicamente los permisos que requiera una funcionalidad concreta.
- Decide la política de copia de seguridad según el diseño de las partidas guardadas.
- Para compilar iOS hace falta macOS con la herramienta de compilación correspondiente.

## Firma y publicación

Antes de una distribución, configura la firma de release propia de cada plataforma.
Las claves y contraseñas se guardan fuera del control de versiones.
La firma de depuración del proyecto inicial sirve para desarrollo.

Para imágenes de tienda, consulta `publicación.md`. La publicación y sus requisitos
se revisan cuando se prepare una versión distribuible.
