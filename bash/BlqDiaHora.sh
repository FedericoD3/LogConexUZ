#!/bin/bash

# Incluir los parametros del grafico
source $(dirname "$0")/ParamsLogConex.dat

# VERIFICACION DE ARGUMENTOS, explicar uso si no se pasaron:
echo $# >> "$DirTmp/$Suf"-Debug.log
if [ $# -eq 0 ]; then         # Si no se pasan argumentos, mostrar como se usa
  echo "USO: BlqDiaHora.sh Fila Columna Minuto /path/a/imagengrid Resultado"
  echo " el primer  argumento es la fecha del mes, que determina el numero de la fila"
  echo " el segundo argumento es el bloque de 10 minutos, que determina el numero de la columna"
  echo " el tercer argumento es el minuto unidad dentro de esa decena, la posicion dentro del bloque"
  echo " el cuarto argumento es el path y nombre del archivo con la imagen del mes"
  echo " el quinto argumento es el indicador de éxito/falla para decidir el color a trazar"
  exit
fi
# ..../BlqDiaHora.sh 22 87 /Discos/Local/web/LogConex/202309_ipify.png ##########

# VALIDACION DE ARGUMENTOS Y ASIGNACION A VARIABLES MEMORABLES:
Fil=$1                                                                  # Pasar el argumento a una variable leible
  if [ -z "$Fil" ]; then Fil=1; fi                                      # Si no se recibió valor o es vacío, asignar el default
  if [ $Fil -lt 1 ]; then Fil=1; fi                                     # Si el valor es menos que el minimo, asignar el minimo
  if [ $Fil -gt 31 ]; then Fil=31; fi                                   # Si el valor es mayor que el maximo, asignar el maximo
  Fil=$(echo $Fil | sed 's/^0*//')                                      # ELiminar el cero precedente para que no lo confunda confunda con octal y explote en "08"
Col=$2                                                                  # Pasar el argumento a una variable leible
  if [ -z "$Col" ]; then Col=1; fi                                      # Si no se recibió valor o es vacío, asignar el default
  if [ $Col -lt 1 ]; then Col=1; fi                                     # Si el valor es menos que el minimo, asignar el minimo
  if [ $Col -gt 144 ]; then Col=144; fi                                 # Si el valor es mayor que el maximo, asignar el maximo
  Col=$(echo $Col | sed 's/^0*//')                                      # ELiminar el cero precedente para que no lo confunda confunda con octal y explote en "08"
Min=$3                                                                  # Pasar el argumento a una variable leible
  if [ -z "$Min" ]; then Min=1; fi                                      # Si no se recibió valor o es vacío, asignar el default
  if [ $Min -lt 0 ]; then Min=1; fi                                     # Si el valor es menos que el minimo, asignar el minimo
  if [ $Min -gt 9 ]; then Min=9; fi                                     # Si el valor es mayor que el maximo, asignar el maximo
Img=$4                                                                  # Pasar el argumento a una variable leible
  if [ -z $Img ]; then                                                  # Si el path/imagen tiene longitud cero,
    Img=$(dirname ${0})                                                 # Iniciarla con el path de este script,
    Img=$Img"/"$(TZ=":America/Caracas" date +'%Y%m')".png"              #  y agregar por defecto AñoMes.png
  fi
Res=$5                                                                  # Pasar el argumento a una variable leible
    if [ -z $Res ]; then                                                # Si el Reso del bloque tiene longitud cero,
    Res="$CarNo"                                                        #  asimir falla
  fi
Suf=$6


# Definir los logs temporales:
Yo=$(basename ${0})                                                     # Tomar el nombre de este script
Yo="${Yo%%.*}"                                                          # Eliminar la extension del script
Deb="$DirTmp/$Suf"-Debug.log                                            # Log de debug de la última ejecución
Scr="$DirTmp/$Suf"_$Yo-Magick.scr                                       # Script para ImageMagick
Yo="($(TZ=":America/Caracas" date +'%Y-%m-%d_%H%M%S') $Yo)"             # Agregar el time tag

echo "($Yo) $0 $1 $2 $3 $4 $5" >> $Deb                                  # Registrar el comando con el que se ejecutó
echo "($Yo) $Fil $Col $Min $Img $Res" >> $Deb                           # Registrar el comando interpretado
echo "($Yo) DEB: $Deb SCR:$Scr" >> $Deb                                 # Registrar los temporales

# Asegurar la existencia de la imagen sobre la cual se dibujara el bloque
if [ ! -f $Img ]; then                                                  # Si el archivo NO existe,
  echo "($Yo) No existe $Img, crearlo" >> $Deb
  echo "($Yo) $(dirname ${0})"/"MesVacio.sh $Img $Suf"  >> $Deb
              $(dirname ${0})"/"MesVacio.sh $Img $Suf                   #  ejecotar el generador de imagen del mes vacio
fi

echo "($Yo) Respaldar $Img antes de procesarlo" >> $Deb
echo "($Yo) cp $Img $DirTmp/$(basename $Img)" >> $Deb
            cp $Img $DirTmp/$(basename $Img)

echo "($Yo) Agregar el minuto $Min del bloque en la columna $Col y fila $Fil" >> $Deb
echo "($Yo)   con el resultado $Res en la imagen $Img" >> $Deb
echo "$Mon $Img " > $Scr
# Calcular los limites horizontales del bloque:
        X1=$(( $mIzq + $bIzq + ($Col-1) * ($ColAncho + $ColSep) +1 ))
echo "($Yo) X1=$mIzq + $bIzq + ($Col-1) * ($ColAncho + $ColSep) +1 =$X1" >> $Deb
        X2=$(( $X1 + $ColAncho - $ColSep ))
echo "($Yo) X2=$X1 + $ColAncho - $ColSep =$X2" >> $Deb
        Y=$(( $mSup + $bSup + $Fil * ( $FilAlto + $FilSep ) -$Min -2 ))         # Calcular la coordenada Y de la linea M en esta fila:
echo "($Yo) Y=$mSup + $bSup + $Fil * ( $FilAlto + $FilSep ) -$Min -2 =$Y" >> $Deb
echo -n "($Yo) Bloque desde X=$X1 hasta X=$X2 a la altura $Y" >> $Deb

case $Res in                                                            # Decidir el color de cada linea según el caracter num M del log:
  $CarOk)
    Color=$ColorOk
    echo " de color" $Color >> $Deb
    echo " -stroke xc:$Color -draw 'line $X1,$Y $X2,$Y'" >> $Scr        # Agregar el trazado de la línea al script
  ;;&
  $CarNo)
    Color=$ColorNo
    echo " de color" $Color >> $Deb
    echo " -stroke xc:$Color -draw 'line $X1,$Y $X2,$Y'" >> $Scr        # Agregar el trazado de la línea al script
  ;;&
  $CarNR)
    echo "" >> $Deb
  ;;&
  *)
    # No trazar nada
esac

echo "$Mon -write $Img" >> $Scr                                         # Terminar el script escribiendo al archivo de imagen del mes
echo "($Yo) /usr/local/bin/magick -script $Scr" >> $Deb
            /usr/local/bin/magick -script $Scr                          # Ejecutar ImageMagic con el script generado

if [[ ! -s $Img ]] ; then
  echo "($Yo) La imagen quedo vacia, se restauro el original" >> $Deb
  echo "($Yo) cp $DirTmp/$(basename $Img) $Img" >> $Deb
              cp $DirTmp/$(basename $Img) $Img
fi

# echo "" >> $Deb                                                         # Separar del log de la siguiente ejecucion
