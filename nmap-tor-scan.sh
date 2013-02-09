#!/bin/bash
# Titulo:	Escaneo de nmap a través de la red Tor
# Fecha:	08/02/13
# Autor:	elsudano
# Versión:	1.0
# Descripción:	Verifica si tenemos todos los binarios necesarios para la ejecución del script
#		configura los diferentes ficheros para el uso del script y ejecuta una interface
#		gráfica para que sea mas amena la ejecución del mismo
# Opciones: Ninguna
# Uso: kdesu ./nmap-tor-scan.sh sin parámetros

REGEX="^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){2}(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))$"
DATOS=($(route | grep default))
PUERTA=${DATOS[1]}
INTERFACE=${DATOS[7]}
BINARIOS=(zenity kdialog tor vidalia privoxy proxychains tee find)
# zenity	Este Fichero es para poder ejecutar la interfaz gráfica
# kdialog	Este Fichero es para poder ejecutar la interfaz gráfica
# tor		Este fichero es para poder ocultar las transacciones a través de internet
# vidalia	Este fichero es una interfaz gráfica para poder configurar y monitorizar a tor
# privoxy	Es un programa que hace de proxy web en la maquina local
# proxychains	Es el encargado de enrrutar todas las peticiones de consola a través del proxy web
# tee		Redirecciona la salida de consola a múltiples procesos
# find		Busca cadenas de texto, ficheros y un largo etc..

FICHEROS_CONFIG=(privoxy.conf proxychains.conf torrc vidalia.conf)
# /etc/privoxy/privoxy.conf	Fichero de configuración del servidor proxy
# /etx/proxychains.conf		Fichero de configuración del enrrutador de consola
# ~/.vidalia/torrc		Fichero de configuración para la red de privacidad
# ~.vidalia/vidalia.conf	Fichero de configuración de la interfaz gráfica

function comprobarbinarios(){
  binOK=0
  for fichero in ${BINARIOS[@]}
  do
    for directorio in $(echo $PATH | tr ':' ' ')
    do
      if [ -f $directorio'/'$fichero ]; then
	#kdialog --title "Ficheros..." --msgbox "el fichero "$fichero" existe"
	binOK=$((binOK+1))
	break
      fi
    done
  done
  if [[ ${#BINARIOS[@]} -eq "$binOK" ]]; then
    kdialog --title "Binarios necesarios " --msgbox "La comprobación de los binarios ha sido un éxito"
  else
    kdialog --title "Binarios necesarios " --msgbox "Uno de los binarios necesarios para ejecutar este script no se ha encontrado\nen su sistema por favor revise la siguiente lista para ver cual es el que falta\n\n${BINARIOS[*]}\n\nTenga en cuenta que estos binarios tienen que estar en su #PATH\npara que el script pueda encontrarlos"
    exit 1
  fi
}

function buscar(){
  echo $(find / -name $1 | tee >(zenity --progress --pulsate))
}

function comprobarbinarios2(){
  binOK=0
  for fichero in ${BINARIOS[@]}
  do
  echo $(find / -name  $fichero | tee >(zenity --progress --pulsate))
    #if [ -f $(find / -name  $fichero | tee >(zenity --progress --pulsate)) ]; then
    #  kdialog --title "Fichero encontrado " --msgbox "El fichero $fichero se ha encontrado en esta dirección $(buscar $fichero)"
    #  binOK=$((binOK+1))
    #fi
  done
  if [[ ${#BINARIOS[@]} -eq "$binOK" ]]; then
    kdialog --title "Binarios necesarios " --msgbox "La comprobación de los binarios ha sido un éxito"
  else
    kdialog --title "Binarios necesarios " --msgbox "Uno de los binarios necesarios para ejecutar este script no se ha encontrado\nen su sistema por favor revise la siguiente lista para ver cual es el que falta\n\n${BINARIOS[*]}\n\nTenga en cuenta que estos binarios tienen que estar en su #PATH\npara que el script pueda encontrarlos"
    exit 1
  fi
}

function main(){
  # esta es la parte de comprobación de binarios
  # aquí es donde tenemos que comprobar que todos los binarios están en el sistema y que se pueden ejecutar
  
  comprobarbinarios2
  kdialog --title "Fichero encontrado " --msgbox "El fichero ${FICHEROS_CONFIG[1]} se ha encontrado en esta dirección $(buscar ${FICHEROS_CONFIG[1]})"
  
  
  #-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  case $(kdialog --title "Aplicación de escaneo a través de la red Tor" --menu "Elija una opción" escanear "Escanear" configuracion "Configuración" salir "Salir") in
      escanear)
	exit;;
      configuracion)
	kdialog --title "Configuracion..." --msgbox "Ventana de Configuración"
	exit;;
      salir)
	if [ $(zenity --question --title "Pregunta" --text "Quiere salir de la aplicación"; echo $?) -eq 1 ]; then
	  main
	fi;;
  esac
}
main