#!/bin/bash

# Incluir los parametros del registro
source $(dirname "$0")/ParamsLogConex.dat

# VERIFICACION DE ARGUMENTOS, explicar uso si no se pasaron:
if [ $1 = "-?" ]; then
  echo "USO:
  LogConex [Dest] [prefijo] [NombreArch] [ConFecha]
    donde:
    Dest = el destino con el cual verificar conexion (IP o URL)
      Si se omite, usa 127.0.0.1
    prefijo = string que precede a la fecha en el nombre de archivo, incluyendo el directorio
      Si se omite, usa el directorio de este script
    NombreArch = especificacion del archivo de log, excluyendo la extension
      Si se omite, se usa _test para componer 202309_test.png
    ConFecha = 1 si se debe anteponer anteceder YYYYMM al  nombre del archivo
      Si se omite, incluye YYYYMM al sufijo
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
ConFecha=$4                                                 # Indicador de omision de la fecha al nombre de archivo
  if [ -z "$NoF" ]; then ConFecha="0"; fi                   #  Si no se recibió valor o es vacío, asignar el default (No agregar la fecha)

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

echo "$0 $1 $2 $3" | tee -a $Deb                                  # Registrar el comando con el que se ejecutó
echo "$Yo $Dest $Pre $Suf" | tee -a $Deb                          # Registrar el comando interpretado
echo "$Yo DEB: $Deb" | tee -a $Deb                                # Registrar los temporales

if  [[ ! $Dest =~ ^http.*$ ]];
then
  # Si no tiene HTTP, usar ping (mas ligero pero no diferenciable por URL en firewall):
  echo -n "$Yo Intentando ping a $Dest. Exit code: $Resp"  | tee -a $Deb
  ping -W 1 -c 1 $Dest > Nul
  Resp=$?
  if [ $Resp -eq "0" ]; then Cod=200; fi         # Forzar HTTP result 200 si el ping fue exitoso, para manejar igual al caso curl
else
  # Si tiene http, intentar conexion l URL
  echo -n "$Yo Intentando curl a $Dest. Bash:$Resp HTTP:$Cod"  | tee -a $Deb
  Cod=$(curl --output /dev/null --silent --connect-timeout 7 --max-time 9 $Dest --write-out "%{http_code}")
  Resp=$?
fi

#if [ $Resp -eq "0" ]; then                                  # Si el destinatario respondio.
if [[ $Resp -eq "0" && $Cod -lt 305 ]]; then                # Si el desninatario respondio (filtrando redireccion 307 al router Digitel sin linea),
  Resul=$CarOk                                              #  usar el caracter definido en CarOk
  else                                                      # En caso contrario,
  Resul=$CarNo                                              #  usar el caracter definido en CarNo
fi
echo " ->" $Resul | tee -a $Deb

# Determinar posición y color del indicador de conexión de este minuto
Fil=$(date +'%d')                     # La fila es directamente la fecha actual
# La columna es el bloque de 10 minutos donde está el minuto actual
H=$(date +'%H')                       # Tomar la hora,
H=$(expr $H + 0)                      #  y eliminar el posible cero precedente (para que no lo confunda con octal)
M=$(date +'%M')                       # Tomar los minutos,
M=$(expr $M + 0)                      #  y eliminar el posible cero precedente (para que no lo confunda con octal)
Col=$(( $H*6 + $M/10 + 1 ))           # Calcular el # de columna de ese bloque de 10 minutos
echo "$Yo Fila $Fil, hora $H $M = columna $Col minuto $Md con un $Resul" | tee -a $Deb

if [ $ConFecha = "0" ];               # Si no se especifico anteponer la fecha,
then
  Img=$Pre$Suf".png"                  # Componer el nombre del archivo con el registro gráfico sin fecha
else
  Img=$Pre$(date +'%Y%m')$Suf".png"   # Componer el nombre del archivo con el registro gráfico con fecha
fi
echo "$Yo Actualizar con el resultado del minuto actual la imagen $Img" | tee -a $Deb
echo "$Yo $(dirname $0)/BlqDiaHora.sh $Fil $Col $Md $Img $Resul $Suf" | tee -a $Deb
          $(dirname $0)/BlqDiaHora.sh $Fil $Col $Md $Img $Resul $Suf

Ahora=$(TZ=":America/Caracas" date +'%H%M')
if [ $Ahora -ge 2355 ]; then                                 # Si ya es casi media noche,
  mkdir ~/LogConexBaks                                       # Crear el directorio de respaldos, por si no existe
  echo "$Yo Repaldar el log del dia que termina" | tee -a $Deb     # Agregar el evento al debug
  echo "cp $Img ~/LogConexBaks/$(basename $Img)" | tee -a $Deb   # Copiar el comando al debug
  DiaSem=$(TZ=":America/Caracas" date +'%a')                 # Evaluar el dia de la semana (no hace falta mas de 7 backups)
  cp $Img ~/LogConexBaks/$(basename $Img)-$DiaSem            # Respaldar la imagen de hoy, por si acaso ImgMagik la borra mañana
fi

if [ $Md -eq 9 ]; then                                       # Si termino el minuto 9, actualizar el archivo online
  echo "$Yo Terminó el bloque de 10min: publicarlo" | tee -a $Deb
  echo "$Yo $(dirname $0)/Publicar.sh $Deb" | tee -a $Deb
            $(dirname $0)/Publicar.sh $Deb                   # Publicar.sh publica todo lo cambiado, el unico parametro es el archivo de debug
fi

echo "" | tee -a $Deb                                              # Separar del log de la siguiente ejecucion
