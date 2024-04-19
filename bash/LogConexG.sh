#!/bin/bash

# Incluir los parametros del registro
source $(dirname "$0")/ParamsLogConex.dat

# VERIFICACION DE ARGUMENTOS, explicar uso si no se pasaron:
if [ $1 = "-?" ]; then
  echo "USO:
  LogConex [Dest] [prefijo] [sufijo]
    donde:
    Dest = el destino con el cual verificar conexion (IP o URL)
      Si se omite, usa 127.0.0.1
    prefijo = string que precede a la fecha en el nombre de archivo, incluyendo el directorio
      Si se omite, usa el directorio de este script
    sufijo = string que sigue a la fecha en nombre de archivo, excluyendo la extension
      Si se omite, se usa _test para componer 202309_test.png
    ej.: LogConex http://api.ipify.org /Algun/Dir/Conveniente/ _WAN1
      al completar los 10 minutos actualiza el archivo /Algun/Dir/Conveniente/YYYYmm_WAN1.png y lo publica
    ej.: LogConex 192.168.1.1 /Algun/Dir/Conveniente/ _LAN
      al completar los 10 minutos actualiza el archivo /Algun/Dir/Conveniente/YYYYmm_LAN.png y lo publica
      /Discos/Local/Scripts/LogConex/Graf/LogConexG.sh http://google.com /Discos/Local/web/LogConex/ _google
      /Discos/Local/Scripts/LogConex/Graf/LogConexG.sh http://api.ipify.org /Discos/Local/web/LogConex/ _ipify
      /Discos/Local/Scripts/LogConex/Graf/LogConexG.sh https://twitter.com /Discos/Local/web/LogConex/ _twitter
      /Discos/Local/Scripts/LogConex/Graf/LogConexG.sh http://duckduckgo.com /Discos/Local/web/LogConex/ _ddg"
  exit
fi

# VALIDACION DE ARGUMENTOS Y ASIGNACION A VARIABLES MEMORABLES:
Dest=$1                                                     # Destino a conectar
  if [ -z "$Dest" ]; then Dest="127.0.0.1"; fi              #  Si no se recibió valor o es vacío, asignar el default
Pre=$2                                                      # Prefijo del archivo de registro
  if [ -z "$Pre" ]; then Pre=$(dirname "$0")"/"; fi         #  Si no se recibió valor o es vacío, asignar el default
Suf=$3                                                      # Sufijo  del archivo de registro
  if [ -z "$Suf" ]; then Pos="_test"; fi                    #  Si no se recibió valor o es vacío, asignar el default

mkdir -p $DirTmp                                            # Creacion del directorio temporal (-p para que cree el path completo)

# Definir los logs temporales:
Yo=$(basename ${0})                                         # Tomar el nombre de este script
Yo="${Yo%%.*}"                                              # Eliminar la extension del script
Yo="($(TZ=":America/Caracas" date +'%Y-%m-%d_%H%M%S') $Yo)" # Agregar el time tag
Deb="$DirTmp/$Suf"-Debug.log                                # Log de debug de la última ejecución
# Dat="$DirTmp/$Suf"-10pings.dat                              # Log de 10 intentos de conexion
# Scr="$DirTmp/$Suf"_$Yo-Magick.scr                           # Script para ImageMagick

M=$(TZ=":America/Caracas" date +'%M')                       # Determinar el minuto actual
Md=$(( ${M#0}%10 ))                                         # Calcular el minuto desde la decena
if [ $Md -eq 0 ]; then mv $Deb $Deb.bak; fi                 # Si es el minuto que empieza la decena, eliminar el debug viejo

echo "$0 $1 $2 $3" >> $Deb                                  # Registrar el comando con el que se ejecutó
echo "$Yo $Dest $Pre $Suf" >> $Deb                          # Registrar el comando interpretado
echo "$Yo DEB: $Deb" >> $Deb                                # Registrar los temporales

if  [[ ! $Dest =~ ^http.*$ ]];
then
  # Si no tiene HTTP, usar ping (mas ligero pero no diferenciable por URL en firewall):
  ping -W 1 -c 1 $Dest > Nul
  Resp=$?
  echo -n "$Yo Intentando ping a $Dest. Exit code: $Resp"  >> $Deb
else
  # Si no es URL interno, es URL (susceptible de ser diferenciable en firewall):
  curl -I --output /dev/null -s $Dest --connect-timeout 20 --max-time 30 > nul
  Resp=$?
  echo -n "$Yo Intentando curl a $Dest. Exit code: $Resp"  >> $Deb
fi

if [ $Resp -eq "0" ]; then                                  # Si el destinatario respondio.
  Resul=$CarOk                                              #  usar el caracter definido en CarOk
  else                                                      # En caso contrario,
  Resul=$CarNo                                              #  usar el caracter definido en CarNo
fi
echo " ->" $Resul >> $Deb

# Determinar posición y color del indicador de conexión de este minuto
Fil=$(date +'%d')                     # La fila es directamente la fecha actual
# La columna es el bloque de 10 minutos donde está el minuto actual
H=$(date +'%H')                       # Tomar la hora, 
H=$(expr $H + 0)                      #  y eliminar el posible cero precedente (para que no lo confunda con octal)
M=$(date +'%M')                       # Tomar los minutos,
M=$(expr $M + 0)                      #  y eliminar el posible cero precedente (para que no lo confunda con octal)
Col=$(( $H*6 + $M/10 + 1 ))           # Calcular el # de columna de ese bloque de 10 minutos
echo "$Yo Fila $Fil, hora $H $M = columna $Col minuto $Md con un $Resul" >> $Deb 
Img=$Pre$(date +'%Y%m')$Suf".png"     # Componer el nombre del archivo con el registro gráfico 
echo "$Yo Actualizar con el resultado del minuto actual la imagen $Img" >> $Deb
echo "$Yo $(dirname $0)/BlqDiaHora.sh $Fil $Col $Md $Img $Resul $Suf" >> $Deb 
          $(dirname $0)/BlqDiaHora.sh $Fil $Col $Md $Img $Resul $Suf

if [ $Md -eq 9 ]; then                # Si termino el minuto 9, actualizar el archivo online
  echo "$Yo Terminó el bloque de 10min: publicarlo" >> $Deb
  echo "$Yo $(dirname $0)/Publicar.sh $Deb" >> $Deb
            $(dirname $0)/Publicar.sh $Deb            # Publicar.sh publica todo lo cambiado, el unico parametro es el archivo de debug
fi

echo "" >> $Deb                                                         # Separar del log de la siguiente ejecucion
