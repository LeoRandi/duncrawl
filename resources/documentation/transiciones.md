# Transición circular

La app envuelve su navegador con `IrisTransition`. No necesita imágenes ni sprites:
una máscara negra deja una abertura circular sobre la escena.

Cada mitad dura 1,5 segundos:

| Tiempo | Avance del cierre | Tamaño relativo de la abertura |
|---|---|---|
| 0 ms | 0 % | 100 % |
| 750 ms | 67 % | 33 % |
| 1100 ms | 50 % | 50 % |
| 1500 ms | 100 % | 0 % |

Entre los 750 y 1100 ms, el cierre retrocede del 67 % al 50 %.
Cada fase usa una interpolación sinusoidal simétrica: acelera al empezar y frena al acercarse
a su extremo, suavizando los cambios de dirección también durante la apertura.
Los porcentajes y tiempos de la tabla se conservan.
La apertura reproduce el movimiento al revés: abertura 0 → 50 → 33 → 100 %
a los 0, 400, 750 y 1500 ms.
Cerrar y abrir juntos duran 3 segundos, con el cambio de escena en negro.

## Reutilización

`IrisTransition.run` recibe el centro global del cierre y una acción `onCovered`
que cambia la escena cuando está completamente tapada. La apertura espera el
layout del destino. Un callback `openingCenter` permite obtener entonces la
posición de un elemento nuevo; si se omite, se usa el centro de la pantalla.

`IrisTransition.centerOf` obtiene el centro de un elemento mediante su `GlobalKey`.
El elemento debe estar montado y haber recibido su layout.

- Entrada al juego: cierre sobre Start y apertura sobre la casilla del personaje.
- Regreso al menú: cierre sobre Main menu, conservando la ventana hasta cubrirla,
  y apertura desde el centro de la pantalla.
- Regreso con el botón del sistema: cierre sobre el personaje.

Las entradas por tacto y foco quedan bloqueadas durante ambas mitades.
Las peticiones simultáneas no inician transiciones adicionales.
