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
#------------------------------------------------------------Cabeceras de Configuración------------------------------------------------------------------------------------------------------------
REGEX="^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){2}(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))$"
RED=($(route | grep default))
PUERTA=${RED[1]}
INTERFACE=${RED[7]}
unset RED
file_config="configfile.conf"
BINARIOS=(kdialog tor vidalia privoxy proxychains tee find)
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
#------------------------------------------------------------Función Buscar----------------------------------------------------------------------------------------------------------------------
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
#------------------------------------------------------------Función Validar Ficheros-------------------------------------------------------------------------------------------------------------
function valida_fichero(){
  local retval=0
  if [[ $# -lt "2" ]]; then
    kdialog --title "Error de Script " --error "Error en la función de comprobación,\nlo siento por favor informe al desarrollador"
    exit 253
  else  
    if [ $1 = "bin" ] && [ -x $2 ]; then
      SITUACION=("${SITUACION[*]} $2")
      retval=1
      kdialog --title "Fichero encontrado " --passivepopup "El fichero $2 se ha encontrado, y es ejecutable" 3
    elif [ $1 = "conf" ] && [ -w $2 ]; then
      SITUACION=("${SITUACION[*]} $2")
      retval=1
      kdialog --title "Fichero encontrado " --passivepopup "El fichero $2 se ha encontrado, y se puede escribir en el" 3
    else
      kdialog --title "Advertencia " --error "El fichero $2 no es un binario, o no se puede acceder a el en formato
escritura por favor recuerde ejecutar este script con el comando kdesu delante si usa
escritorio KDE o gksu delante si usa el escritorio GNOME"
      exit 3
    fi
  fi
  return $retval 
}
#------------------------------------------------------------Función Comprobar Ficheros--------------------------------------------------------------------------------------------------------
function comprobar(){
  local valido=0
  if [ $1 = "bin" ]; then
    local array=(${BINARIOS[@]})
  elif [ $1 = "conf" ]; then
    local array=(${FICHEROS_CONFIG[@]})
  else
    kdialog --title "Error de Script " --error "Error en la función de comprobación,\nlo siento por favor informe al desarrollador"
    exit 253
  fi
  for fichero in ${array[@]}
  do
    df=($(buscar $fichero)) # variable df = directorios de ficheros
    if [[ ${#df[@]} -gt "1" ]]; then
      for opcion in ${df[@]}
      do
	local opciones="$opciones $opcion $opcion false "
      done
      seleccion=$(kdialog --title "Elija una opción " --radiolist " Elija donde se encuentra el\nfichero: $fichero en su sistema " $opciones)
      if [[ $? = "0" ]]; then
	if [ $1 = "bin" ]; then
	  if [[ $(valida_fichero bin $seleccion;echo $?) -eq "1" ]]; then
	    valido=$(($valido+1))
	  fi
	elif [ $1 = "conf" ]; then
	  if [[ $(valida_fichero conf $seleccion;echo $?) -eq "1" ]]; then
	    valido=$(($valido+1))
	  fi
	fi
      else
	kdialog --title "Advertencia " --sorry "Si el fichero $fichero no estaba en la lista anterior\nsignifica que no se encuentra en su\nsistema y deberá instalarlo/crearlo"
	exit 4
      fi
      opciones=""
    elif [[ ${#df[@]} -eq "1" ]] && [ -f ${df[0]} ]; then
      if [ $1 = "bin" ]; then
	if [[ $(valida_fichero bin ${df[0]};echo $?) -eq "1" ]]; then
	  valido=$(($valido+1))
	fi
      elif [ $1 = "conf" ]; then
	if [[ $(valida_fichero conf ${df[0]};echo $?) -eq "1" ]]; then
	  valido=$(($valido+1))
	fi
      fi
    else
      kdialog --title "Fichero NO encontrado " --passivepopup "El fichero $fichero no se ha encontrado en su sistema\npor favor instalelo y vuelva a ejecutar este script" 5
      local no_encontrados="$no_encontrados $fichero"
    fi
  done
  if [[ ${#array[@]} -eq "$valido" ]]; then
    kdialog --title "Fichero necesario " --passivepopup "La comprobación de los ficheros ha sido un éxito" 3
    retval=1
  else
    kdialog --title "Fichero necesario " --msgbox "Uno o varios de los ficheros necesarios para ejecutar este script no
se ha encontrado en su sistema por favor instale/cree los siguientes ficheros
y vuelva a ejecutar este script\n
$no_encontrados"
    exit 5
  fi
  unset no_encontrados
  unset array
  unset opciones
  unset valido
  return $retval
}
#------------------------------------------------------------Función Submenu Configuración--------------------------------------------------------------------------------------------------------
function submenu_configuracion(){
  local retval=0
  case $(kdialog --title "Configuración" --menu " " reiniciar "Reiniciar los valores por defecto" mirar "Ver los valores almacenados") in
    reiniciar)
      rm $(pwd)/$file_config
      submenu_configuracion;;
    mirar)
      cat $(pwd)/$file_config
      submenu_configuracion;;
  esac
  return $retval
}
#------------------------------------------------------------Función Menú Principal---------------------------------------------------------------------------------------------------------------
function menu_main(){
  # esta es la parte de comprobación de binarios y ficheros de configuración
  # aquí es donde tenemos que comprobar que todos los binarios y los ficheros
  # de configuración necesarios están en el sistema y que se pueden acceder a ellos.

  if [ -e $(pwd)/$file_config ]; then
    if [ $(cat $(pwd)/$file_config) != "1" ]; then
      
      if [[ $(comprobar bin;echo $?) -eq "1" ]] && [[ $(comprobar conf;echo $?) -eq "1" ]]; then
	echo "1" >$file_config
	for sitio in ${SITUACION[@]}
	do
	  echo $sitio >>$file_config
	done
      fi
    fi
  else
    echo "0" >$file_config
    menu_main
  fi
  echo ${SITUACION[@]}
  #-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  case $(kdialog --title "Aplicación de escaneo a través de la red Tor" --menu "Elija una opción" escanear "Escanear" configuracion "Configuración" salir "Salir") in
      escanear)
	exit;;
      configuracion)
	submenu_configuracion
	if [[ $? -eq "0" ]]; then
	  menu_main
	fi;;
      salir)
	if [[ $(kdialog --title "Configuración" --yesno "Quiere salir de la aplicación"; echo $?) -eq "1" ]]; then
	  menu_main
	fi;;
  esac
  exit 0
}
menu_main