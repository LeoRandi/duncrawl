https://dev.to/iamsahilsonawane/a2hs-in-flutter-web-3cln#show-a2hs-prompt-with-flutter

Para verificar que es válida, se debe usar https://chrome.google.com/webstore/detail/lighthouse/blipmdconlkpinefehnmjammfjpmpbjk

También con la página abierta > F12 > Aplicación > (menú izquierda) Archivo de manifiesto > Ver si hay alertas.
Si se indica  que no se han encontrado los iconos, entonces no funcionará la PWA.

# Errores solucionados

### Las imágenes indicadas en el manifest no las puede encontrar el navegador, se indica en devtools de chrome (F12)
Por algún motivo, la carpeta donde se indicaban los iconos, existía para otro tipo de iconos "url_web/icons/" y los
iconos para la PWA no existían. Simplemente hay que cambiar los iconos del manifest de ruta.
