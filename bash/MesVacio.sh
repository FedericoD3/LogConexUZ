#!/bin/bash

Img=$1                                 # Pasar el argumento a una variable leible
if [ -z $Img ]; then                   # Si el path/imagen tiene longitud cero,
  Img="test.png"                       #  Usar un valor default
fi

cp $Img ${Img%.*}" mes pasado.png"     # Copiar la cuadricula del mes que termino a la cuadricula del mes pasado
cp $(dirname ${0})"/Vacio.png" $Img    # Copiar la cuadricula pre-generada del mes vacio al mes en curso