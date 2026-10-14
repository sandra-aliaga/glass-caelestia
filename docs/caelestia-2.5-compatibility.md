# Compatibilidad con Caelestia 2.5

La interfaz de glass-caelestia conserva su barra superior y sus ajustes QML.
Usa los componentes instalados por `caelestia-shell` 2.5.0 y Quickshell 0.3.2,
compilados para Qt 6.12.0.

Los componentes de imagen ahora se importan desde `Caelestia.Images`, los
modelos desde `Caelestia.Models`, los indicadores desde `Caelestia.Components`
y las extensiones de Hyprland desde `Caelestia.Services`. El modulo antiguo
`Caelestia.Internal` ya no existe.

Esto adapta la interfaz personalizada a las bibliotecas nuevas; no sustituye
sus paneles por los de la interfaz estandar ni incorpora todos sus cambios.

Se comprobo la carga en una sesion Wayland con `Configuration Loaded`.
Las ventanas secundarias y todas sus interacciones requieren revision manual.
`git diff --check` y el formato de las importaciones pasan. El `qmlformat`
instalado rechaza las directivas `pragma` heredadas, por lo que no se declara
una verificacion completa del formato de los archivos.

## Mejoras compatibles incorporadas

- Ethernet: excluye interfaces virtuales y conserva la lista anterior si falla
  la consulta. Adaptado del cambio upstream `750e67d9`.
- Teclado: evita avisos duplicados o con distribucion desconocida. Adaptado de
  `a76ab282`.
- Grabacion: actualiza el estado de grabaciones iniciadas por fuera de la
  interfaz y detiene el contador al pausar. Consulta el estado solo cuando
  estan visibles los controles del panel de esquina o del sidebar. Adaptado
  de `d17cbf01` al ciclo de vida de los paneles glass.
- Bateria: evita mostrar carga completa mientras el tiempo hasta la carga
  esta calculandose; corrige las horas residuales al formatear dias.
- Interruptores: admite un estado deshabilitado con colores diferenciados,
  conservando las dimensiones y animaciones glass.

Validacion: once escenarios del grabador con comandos simulados, dos
escenarios de Ethernet con NetworkManager simulado y carga completa en
Wayland. No se inicio una grabacion real ni se modificaron conexiones de red.
El formateador disponible no admite toda la sintaxis QML heredada; se
conserva el estilo existente cuando su salida altera la estructura del archivo.

Los cambios de VPN, traducciones y configuracion tipada de upstream requieren
una migracion adicional de los paneles y no forman parte de esta integracion.

Para reiniciar la interfaz activa:

```fish
systemctl --user restart caelestia-shell.service
```

Para consultar errores:

```fish
journalctl --user -u caelestia-shell.service -n 40 --no-pager
```
