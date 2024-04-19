#!/bin/bash

# Incluir los parametros del grafico
source $(dirname "$0")/ParamsLogConex.dat

# VALIDACION DE ARGUMENTOS Y ASIGNACION A VARIABLES MEMORABLES:
Img=$1                                                            # Pasar el argumento a una variable leible
  if [ -z $Img ]; then                                            # Si el path/imagen tiene longitud cero,
    Img=$(dirname ${0})                                           # Iniciarla con el path de este script,
    Img=$Img"/"$(TZ=":America/Caracas" date +'%Y%m')"_test.png"   #  y agregar por defecto AñoMes.png
  fi
Suf=$2                                                            # Sufijo  del archivo de registro
  if [ -z "$Suf" ]; then Suf="_test"; fi                          # Si no se recibió valor o es vacío, asignar el default

mkdir -p $(dirname $Img)                                          # Asegurarse que el directorio esté creado
rm $Img                # Eliminar la imagen existente para asegurarse que sea nueva y vacía

# Definir los logs temporales:
Yo=$(basename ${0})                                               # Tomar el nombre de este script
Yo="${Yo%%.*}"                                                    # Eliminar la extension del script
Yo="($(TZ=":America/Caracas" date +'%Y-%m-%d_%H%M') $Yo)"         # Agregar el time tag
Deb="$DirTmp/$Suf"-Debug.log                                      # Log de debug de la última ejecución
#Dat="$DirTmp/$Suf"_$Yo-10pings.dat                                # Log de 10 intentos de conexion
Scr="$DirTmp/$Suf"-Magick.scr                                     # Script para ImageMagick

echo "$Yo $0 $1 $2" >> $Deb                                       # Registrar el comando con el que se ejecutó
echo "$Yo $Img $Suf" >> $Deb                                      # Registrar el comando interpretado
echo "$Yo DEB: $Deb SCR:$Scr" >> $Deb                             # Registrar los temporales

ImgAncho=$(( $mIzq + $bIzq + $Cols * $ColAncho + (( $Cols - 1 )) * $ColSep + $bDer ))
ImgAlto=$(( $mSup + $bSup + $Fils * $FilAlto + (( $Fils - 1 )) * $FilSep + $bInf))
echo "$Yo Imagen a crear de: $ImgAncho x $ImgAlto" >> $Deb

# Parametros globales de este script
#  para ver cuales fonts hay, ejecutar:
#  magick -list font
echo "$Mon -font $FontNom -pointsize $FontTam" > $Scr
# Lienzo vacío transparente (inc margenes y bordes):
echo "-size '$(( $ImgAncho + 5 )) x $ImgAlto' xc:none" >> $Scr

# Rectángulo color azul noche, que ocupe todo el mes:
X1=$(( $mIzq + $bIzq ))
Y1=$(( $mSup + $bSup))
X2=$ImgAncho
Y2=$ImgAlto
Color=$ColorNoc
echo "$Yo Rectángulo de color $Color desde $X1,$Y1 hasta $X2,$Y2 (noche)"  >> $Deb
echo "-fill xc:$Color -draw 'rectangle $X1,$Y1 $X2,$Y2'" >> $Scr

# Rectángulo color azul cielo, que ocupe todo el mes entre 0600 y 1800:
X1=$(( $mIzq + $bIzq + $ColAncho * 6 * 6 + $ColSep * (6*6-1)+1 ))
Y1=$(( $mSup + $bSup))
X2=$(( $mIzq + $bIzq + $ColAncho * 18 * 6 + $ColSep * (18*6-1) ))
Y2=$ImgAlto
Color=$ColorDia
echo "$Yo Rectángulo de color $Color desde $X1,$Y1 hasta $X2,$Y2 (dia)"  >> $Deb
echo "-fill xc:$Color -draw 'rectangle $X1,$Y1 $X2,$Y2'" >> $Scr

#### Trazar lineas horizontales tenues desde debajo del dia 0 (arriba del 1) hasta debajo del dia 31
X1=$(( $mIzq + $bIzq ))
X2=$ImgAncho
Color=$ColorSep
echo -n "$Yo Lineas horizontales color $Color tenue entre $X1 y $X2 en Y= "  >> $Deb
for FilNum in {0..31}
do
  Y=$(( $mSup + $bSup + $FilNum * ( $FilAlto + $FilSep ) -1 ))
  echo -n " $Y"  >> $Deb
  echo "-stroke xc:$Color -draw 'line $X1,$Y $X2,$Y'" >> $Scr  
  # Si no es el dia cero, agregar el label de la fecha:
  echo 
  if [ $FilNum -gt 0 ] && [ $FilNum -lt 10 ]; then
    echo "-stroke none -fill black -draw 'text 4,$(( $Y-1 )) \" $FilNum\"'" >> $Scr
  fi
  if [ $FilNum -ge 10 ]; then
    echo "-stroke none -fill black -draw 'text 4,$(( $Y-1 )) \"$FilNum\"'" >> $Scr
  fi
done
echo "" >> $Deb
#############################

#### Trazar lineas horizontales resaltadas desde debajo del dia 0 (arriba del 1) hasta debajo del dia 30, de 5 en 5
X1=$(( $mIzq + $bIzq ))
X2=$ImgAncho
Color=$ColorSepRes
echo -n "$Yo Lineas horizontales color $Color resaltado entre $X1 y $X2 en Y= "  >> $Deb
for FilNum in {0..30..5}
do
  Y=$(( $mSup + $bSup + $FilNum * ( $FilAlto + $FilSep ) -1 ))
  echo -n " $Y"  >> $Deb
  echo "-stroke xc:$Color -draw 'line $X1,$Y $X2,$Y'" >> $Scr
done
# Agregar una linea resaltada debajo del dia 31
  Y=$(( $mSup + $bSup + 31 * ( $FilAlto + $FilSep ) -1 ))
  echo " $Y"  >> $Deb
  echo "-stroke xc:$Color -draw 'line $X1,$Y $X2,$Y'" >> $Scr
#############################

#### Trazar lineas verticales resaltadas desde la izquierda de las 00 (col #1) hasta la izquierda del 24 (col #145)
Y1=$(( $mSup + $bSup +  0 * ( $FilAlto + $FilSep ) -1 ))
Y2=$(( $mSup + $bSup + 32 * ( $FilAlto + $FilSep ) -1 ))
Color=$ColorSepRes
echo -n "$Yo Lineas  verticales  color $Color resaltado entre $Y1 y $Y2 en X= "  >> $Deb
for Col in {1..145..6}
do
  X=$(( $mIzq + $bIzq + ($Col-1) * ($ColAncho + $ColSep) ))
  echo -n " $X"  >> $Deb
  echo "-stroke xc:$Color -draw 'line $X,$Y1 $X,$Y2'" >> $Scr
  Hora=$(( Col/6 ))
  if [ $Hora -lt 10 ]; then
    Hora="0"$Hora
  fi
  echo "-stroke none -fill black -draw 'text $(( $X-5 )),$(( $mSup-2 )) \"$Hora\"'" >> $Scr
done
echo "" >> $Deb
#############################

# Instalacion del font monoespaciado:
#  wget https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip
#  unzip Hack-v3.003-ttf.zip -d ~/Hack-v3.003-ttf
#  sudo mv ~/Hack-v3.003-ttf/ttf /usr/share/fonts/truetype/hack_V3
#    wget https://rubjo.github.io/victor-mono/VictorMonoAll.zip
#    unzip VictorMonoAll.zip -d ~/VictorMonoAll
#    sudo mv ~/VictorMonoAll/TTF /usr/share/fonts/truetype/VictorMonoAll
#  fc-cache -f -v
#  fc-list | grep "Hack"
#    fc-list | grep "Victor"

echo "$Yo -write $Img" >> $Deb  # Terminar el script escribiendo al archivo de imagen del mes
echo "-write $Img" >> $Scr  # Terminar el script escribiendo al archivo de imagen del mes

echo "$Yo /usr/local/bin/magick -script $Scr" >> $Deb
            /usr/local/bin/magick -script $Scr

## Elimnar la extension del archivo recien creado para el log grafico:
#Img="${Img%%.*}"
## Agregar al principio de la lista de archivos el nombre del archivo de log grafico recien creado:
##  ( sed: directo en el archivo en disco: 1 sustitucion de /inicio-de-linea/ por /nombre-del-archivo-nuevo+linea-nueva/ )
#sed -i '1s/^/$(basename $Img)\n/' $(dirname $Img)/logs.txt
# echo $(basename $Img) >> $(dirname $Img)/logs.txt          # Agregar el PNG recien creado a la Lista de PNG en este directorio

cd $(dirname $Img)                                           # Cambiar al directorio de los logs gráficos

ls -1r  *.png | sed 's/.png//' > $(dirname $Img)/logs.txt    # Registrar los PNG existentes, uno por línea, en orden alfabetico reverso

echo "" >> $Deb                                              # Separar del log de la siguiente ejecucion
