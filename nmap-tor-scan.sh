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

function buscar(){
  if [ $1 != "" ]; then
    ref=$(kdialog --progressbar "Buscando..." 3)
    sleep 2
    qdbus ${ref} org.kde.kdialog.ProgressDialog.setLabelText "Buscando ficheros necesarios..."
    qdbus ${ref} Set org.kde.kdialog.ProgressDialog value 1
    local retval=$(find / -name $1)    
    qdbus ${ref} Set org.kde.kdialog.ProgressDialog value 2
    sleep 2
    qdbus ${ref} Set org.kde.kdialog.ProgressDialog value 3
    qdbus ${ref} org.kde.kdialog.ProgressDialog.close
  else
    kdialog --title "Error " --error "La función de búsqueda no ha funcionado bien"
  fi
  echo $retval
}

function comprobarbinarios(){
  local binOK=0
  local retval=0
  for fichero in ${BINARIOS[@]}
  do
    dfb=($(buscar $fichero)) # variable dfb = directorios de ficheros binarios
    if [[ ${#dfb[@]} -gt "1" ]]; then
      for opcion in ${dfb[@]}
      do
	local opciones="$opciones $opcion $opcion false "
      done
      seleccion=$(kdialog --title "Elija una opción " --radiolist " Elija donde se encuentra el\nfichero: $fichero en su sistema " $opciones)
      if [[ $? = "0" ]]; then
	if [ -x $seleccion ]; then
	  SITUACION_BINARIOS=("${SITUACION_BINARIOS[*]} $seleccion\n")
	  binOK=$((binOK+1))
	else
	  kdialog --title "Advertencia " --sorry "El fichero $fichero no es un binario\npor favor vuelva a ejecutar el script\ny seleccione un fichero correcto"
	  exit 1
	fi
      else
	kdialog --title "Advertencia " --sorry "Si el fichero $fichero no estaba en la lista anterior\nsignifica que no se encuentra en su\nsistema y deberá instalarlo"
	exit 1
      fi
      opciones=""
    elif [[ ${#dfb[@]} -eq "1" ]] && [ -f ${dfb[0]} ]; then
      kdialog --title "Fichero encontrado " --passivepopup "El fichero $fichero se ha encontrado en esta dirección ${dfb[0]}" 5
      SITUACION_BINARIOS=("${SITUACION_BINARIOS[*]} ${dfb[0]}\n")
      binOK=$((binOK+1))
    else
      kdialog --title "Fichero NO encontrado " --passivepopup "El fichero $fichero no se ha encontrado en su sistema\npor favor instalelo y vuelva a ejecutar este script" 5
      binarios_no_encontrados="$binarios_no_encontrados $fichero"
      retval= "1"
    fi
  done
  if [[ ${#BINARIOS[@]} -eq "$binOK" ]]; then
    kdialog --title "Binarios necesarios " --passivepopup "La comprobación de los binarios ha sido un éxito" 5
  else
    kdialog --title "Binarios necesarios " --msgbox "Uno o varios de los binarios necesarios para ejecutar este script no
se ha encontrado en su sistema por favor instale los siguientes binarios
y vuelva a ejecutar este script\n
$binarios_no_encontrados"
    exit 1
  fi
  return $retval
}

function configuracion(){
  local retval=0
  case $(kdialog --title "Configuración" --menu " " reiniciar "Reiniciar los valores por defecto" mirar "Ver los valores almacenados" volver "Volver") in
    reiniciar)
      rm $(pwd)/first
      configuracion;;
    mirar)
      cat $(pwd)/first
      configuracion;;
    volver)
      main;;
  esac
  return $retval
}

function main(){
  # esta es la parte de comprobación de binarios
  # aquí es donde tenemos que comprobar que todos los binarios están en el sistema y que se pueden ejecutar

  if [ -e $(pwd)/first ]; then
    if [ $(cat $(pwd)/first) != "1" ]; then
      comprobarbinarios
      if [[ $? -eq "0" ]]; then
	echo "1" >first
      fi
    fi
  else
    echo "0" >first
    main
  fi
  echo ${SITUACION_BINARIOS[*]}
  #-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  case $(kdialog --title "Aplicación de escaneo a través de la red Tor" --menu "Elija una opción" escanear "Escanear" configuracion "Configuración" salir "Salir") in
      escanear)
	exit;;
      configuracion)
	configuracion
	echo $?;;
      salir)
	if [ $(zenity --question --title "Pregunta" --text "Quiere salir de la aplicación"; echo $?) -eq 1 ]; then
	  main
	fi;;
  esac
  exit 0
}
main