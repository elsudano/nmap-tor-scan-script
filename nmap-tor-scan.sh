#!/bin/bash
# Titulo:	Escaneos de nmap a traves de la red Tor
# Fecha:	08/02/13
# Autor:	elsudano
# Versión:	1.0
# Descripción:	Verifica si tenemos todos los repositorios necesarios para la ejecución del script
#		configura los diferentes ficheros para el uso del script y ejecuta una interface
#		grafica para que sea mas amena la ejecución del mismo
# Opciones: Ninguna
# Uso: kdesu ./nmap-tor-scan.sh sin parametros

REGEX="^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){2}(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))$"
DATOS=($(route | grep default))
puerta=${DATOS[1]}
interface=${DATOS[7]}

function main(){
  # esta es la parte de comprobación de binarios
  # aquí es donde tenemos que comprobar que todos los binarios estan en el sistema y que se pueden ejecutar
  
  #-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  case $(kdialog --title "Aplicación de escaneo a traves de la red Tor" --menu "Elija una opción" escanear "Escanear" configuracion "Configuración" salir "Salir") in
      escanear)
	kdialog --title "Escaneando..." --progressbar "Escanenado... por favor aguarde" 10
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