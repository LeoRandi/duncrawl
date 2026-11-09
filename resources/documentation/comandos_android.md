# Verificar el certificado de un APK firmado con firma JAR

Ejemplo, sustituyendo la ruta por el artefacto real:

```powershell
keytool -printcert -jarfile duncrawl.apk
```

Este comando inspecciona el certificado JAR; no demuestra por sí solo la validez
de todos los esquemas de firma Android. Para verificar un APK, usa también
`apksigner verify --verbose --print-certs <ruta_al_apk>` del Android SDK.
