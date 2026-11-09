# Notas de diagnóstico Flutter

Estas notas conservan casos históricos. Los paquetes, versiones y plataformas citados
no se presuponen presentes en Dungeon Crawler 0. Antes de aplicar una receta, reproduce
el fallo y comprueba su compatibilidad con el SDK y las dependencias del proyecto.

### Error al compilar en Android

* What went wrong:
Execution failed for task ':app:processDevReleaseResources'.
> A failure occurred while executing com.android.build.gradle.internal.res.LinkApplicationAndroidResourcesTask$TaskAction
   > Android resource linking failed
     aapt2 E 12-01 10:10:47 10120 96536 LoadedArsc.cpp:94] RES_TABLE_TYPE_TYPE entry offsets overlap actual entry data.
     aapt2 E 12-01 10:10:47 10120 96536 ApkAssets.cpp:152] Failed to load resources table in APK '/Users/developer/Library/Android/sdk/platforms/android-35/android.jar'.
     error: failed to load include path /Users/developer/Library/Android/sdk/platforms/android-35/android.jar.

Se ha solucionado actualizando la versión de gradle en:
- gradle/wrapper/gradle-wrapper.properties > distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-all.zip
- build.gradle > classpath 'com.android.tools.build:gradle:8.2.0'

### Map<dynamic, dynamic> no es un tipo de Map<String, dynamic>
Convierte el valor con `Map<String, dynamic>.from(valor)` antes de usarlo como un
mapa con claves de texto. Esto comprueba los tipos; no transforma claves de otro
tipo en cadenas.

### La aplicación se congela al iniciar la HomePage principalmente cuando los manager están arrancando después del primer inicio
Algún modelo tiene una consulta a otro modelo dependiente sin ningún criterio, posiblemente con un where.

Esto genera que por cada modelo principal, se esté recorriendo todo el listado de modelos dependientes. Lo cual repercute mucho en el rendieminto.

Se debe evaluar algún campo del modelo principal para saber si hay que hacer la consulta. O eliminar el modelo dependiente y guardarlo como un json en la tabla del modelo principal.

### ssl_client_socket_impl
Comprueba el certificado del servidor, el entorno de ejecución y la versión del
paquete implicado antes de aplicar una solución. La incidencia histórica
https://github.com/flutter/flutter/issues/27597#issuecomment-657293123 puede servir
de contexto si coincide con el error observado. No desactives la validación TLS
como solución permanente ni presupongas una corrección privada ausente del proyecto.

### El backend devuelve un 405 con la respuesta vacía.
La url del endpoint se ha puesto mal desde el front.

### Las imágenes cargan la primera vez y se queda la UI bloqueada.
Revisar que no haya un doble FittedBox.

### Hive => HiveError: Cannot write, unknown type:
- Conflicto en el typeId con otro modelo.
- Conflicto en el nombre de la tabla (dao) con otro DAO.
- En el adaptador, se está insertando un objeto no válido (por haberle puesto el decorador de Hive).
- En el modelo Hive, hay 2 campos con el mismo índice en el decorador.

### Hive => RangeError: Not enough bytes available
- Ejecutar el script de generación de los adaptadores.
    flutter packages pub run build_runner build
- Desinstalar app, para borrar la base de datos actual.
- Checkear que no falte ningún hueco, aunque sea escribir un write vacío, para que el
    tamaño esperado en bytes sea igual al real

### Compilación iOS error module '*' not found
- Hay que verificar que el fichero Podfile.lock tenga la dependencia con la versión correcta.
- Compilar con flutter.
- Abrir XCode pulsando sobre el fichero Runner.xcworkspace.

### FlutterLocalNotificationsPlugin.java:1554: error: cannot find symbol if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
- 1. Sobreescribir dependencia problemática con flutter_local_notifications: "9.4.0"

### La aplicación no inicia en debug mode, se queda la pantalla en blanco
- 1. Desintalar la aplicación del equipo.
- 2. Ejecutar la aplicación con flutter run --debug
- 3. La aplicación debería funcionar las siguientes veces al pulsar F5. Si no repetir el proceso.
- 4. Si sigue sin funcionar, ejecutar el comando flutter run --verbose para ver qué puede estar fallando.

### Flutter Error waiting for a debug connection: The log reader stopped unexpectedly
- 1. flutter channel stable
- 2. flutter upgrade
- 3. flutter clean

### Error de compilación: The specified language version is too high
Es posible que alguna de las dependencias sobreescritas cojan una versión que utiliza una versión de Dart demasiado alta, prueba con una menor.

### Error al obtener la tabla ------- : RangeError: Not enough bytes available.
Errores relacionados con las posiciones del array de byte del fichero .g de hive, donde hay posiciones vacías, por no escribir ningún dato o escribir siempre null.

Cuando se elimine un campo, no se debe quitar el writeByte y el write, sino escribir cualquier dato dentro, como un string vacío.

      ..writeByte(17)
      ..write("")

El error da en el bucle del read del fichero .g de hive. Al tener una posición sin escribir o escribiendo null, el puntero (reader) no contiene todas las posiciones de numOfFields.

  final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

### Flutter error RenderBox was not laid out: RenderRepaintBoundary#9c1b2 relayoutBoundary=up9 NEEDS-PAINT
Pasa cuando combinas Columns o Rows con ListView sin un tamaño fijo. La solución es dar un tamaño, poner el shrinkWrap a true o evitar hacerlo de esa forma.

https://stackoverflow.com/questions/52801201/flutter-renderbox-was-not-laid-out

### Error al compilar en iOS: CocoaPods's specs repository is too out-of-date
- 1. flutter clean
- 2. cd a carpeta ios
- 3. Borrar fichero Podfile.lock
- 4. Ejecutar: pod install --repo-update

### No funciona el intellisense en un paquete
Ese paquete o alguno de los que importa tiene una línea de "import" o "export" con una sintaxis incorrecta. Esto no lo detecta el propio SDK pero provoca que no funcionen las sugerencias. El problema me dio por un "import" donde en su ruta había una doble barra "//".

### [firebase_core] iOS could not build module 'firebase_core'
Lo he resuleto poniendo las dependencias de Firebase dentro de "target 'Runner' do".

https://github.com/FirebaseExtended/flutterfire/issues/3272

### Problemas con las dependencias o el fichero pod al compilar en iOS
Antes de generar el instalable desde XCode o ejecutar un comando de "pod", hay que ejecutar o compilar el proyecto desde flutter,
aunque sea en modo debug. Si no se hace antes, al instalar pod, no obtendrá todas las dependencias de proyecto y generará errores.

Para volver a obtener los pods, se accede a la carpeta de ios con la terminal:
- Se borra el fichero Podfile.lock.
- Se ejecuta: "pod deinstegrate" (esto debería borrar la carpeta Pod**).
- Se ejecuta: "pod install".

Algunas dependencias del fichero Podfile, como las de firebase, se deben poner dentro de "target 'Runner' do".

### Problemas con las dependencias de Flutter al crear un plugin nativo
Si las dependencias de Flutter no se resuelven, hay que añadir la siguiente línea al fichero build.gradle dentro de dependencies. Cuando se vaya a compilar hay que comentarla.

    implementation files('C:\\src\\flutter\\bin\\cache\\artifacts\\engine\\android-x64\\flutter.jar')


### No se actualizan los modelos de la base de datos y se envían en cada iteración del sincronizador
Revisar si el DAO en su campo "primaryColumn" devuelve los mismos campos que el objeto PK del modelo.

### La aplicación en modo release se cierra nada más iniciarse o se queda la pantalla en blanco
Hay que poner la siguiente línea lo primero en el onCreate del MainActivity:
    this.getIntent().putExtra("enable-software-rendering", true);

https://github.com/flutter/flutter/issues/51447

### El prefijo "tools" para el atributo "tools:replace" asociado a un tipo de elemento "application" no está enlazado.
Hay que añadir una línea a la etiqueta manifest en el fichero Manifest

    xmlns:tools="http://schemas.android.com/tools"

https://stackoverflow.com/questions/32002361/how-to-fix-android-manifest-xml-naming-conflict


### PlatformException(firebase_core, java.util.concurrent.ExecutionException: java.util.concurrent. ExecutionException: java.lang.NullPointerException: FirebaseCrashlytics component is not present., null, null)
Se dio por tener añadido tools:node="replace" al manifest.

### Una aplicación con backend falla al sincronizar datos
Si se añade un backend y una petición devuelve un error HTTP 500, comprueba la
respuesta y los registros del servidor antes de cambiar el cliente. Un fallo de
configuración de la base de datos puede impedir obtener datos incluso en una
instalación nueva. No presupongas que el juego requiere sincronización o usuarios.

### Error de tipos solo en modo release
TypeError: Instance of 'minified:hh': type 'minified:hh' is not a subtype of type 'minified:hP'
main.dart.js:14207     at Object.c (https://example.com/main.dart.js:13026:3)
main.dart.js:14207     at Object.bil (https://example.com/main.dart.js:13678:18)
main.dart.js:14207     at mN.bzJ [as a] (https://example.com/main.dart.js:13677:3)
main.dart.js:14207     at vL.z_ (https://example.com/main.dart.js:92000:6)
main.dart.js:14207     at kK.F6 (https://example.com/main.dart.js:95244:58)
main.dart.js:14207     at kK.hA (https://example.com/main.dart.js:95174:3)
main.dart.js:14207     at kK.hA (https://example.com/main.dart.js:95302:3)
main.dart.js:14207     at wV.GE (https://example.com/main.dart.js:94942:3)
main.dart.js:14207     at wV.fn (https://example.com/main.dart.js:94902:16)
main.dart.js:14207     at wV.m7 (https://example.com/main.dart.js:95060:32)
main.dart.js:14207 Another exception was thrown: Instance of 'minified:kw<void>'

El error se daba por tener 2 widgets de tipo Stack anidados. El segundo estaba a su vez, dentro de un Expanded.
Quedaba así Stack > Expanded > Stack.

# Problemas de pependencias (principalmente firebase) al ejecutar o construir.
La opción más rápida es sobreescribir todas las dependencias de firebase en la aplicación principal con las mismas
versiones de pubspect.lock de un proyecto donde funcione correctamente.


dependency_overrides:
  cloud_firestore: '3.1.8'
  cloud_firestore_web: '2.6.8'
  cloud_firestore_platform_interface: '5.4.13'
  firebase_core: '1.12.0'
  firebase_core_platform_interface: '4.2.4'
  firebase_core_web: '1.5.4'
  firebase_storage: '10.2.7'
  firebase_storage_platform_interface: '4.0.14'
  firebase_storage_web: '3.2.8'
  \# Otros
  intl: ^0.17.0
  async: ^2.6.1
  logging: ^0.11.3
  sqflite: ^2.2.0+3
   \# Solución: Could not resolve all artifacts for configuration ':image_picker_android:debugUnitTestRuntimeClasspath'.
  image_picker_android: 0.8.4+13

# No se puede instalar la APP desde Google Play (da error)
Si ha instalado un APK directamente. Al subir un AppBundle a la Google Play. Aunque se desinstale el APK, se quedan ficheros intermamente y genera un conflicto que impide instalar desde Google Play.

No se ha encontrado solución todavía.
