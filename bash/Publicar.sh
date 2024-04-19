#!/bin/bash

# Incluir los parametros del grafico
source $(dirname "$0")/ParamsLogConex.dat

# Definir los logs temporales:
Yo=$(basename ${0})                                         # Tomar el nombre de este script
Yo="${Yo%%.*}"                                              # Eliminar la extension del script
Yo="($(TZ=":America/Caracas" date +'%Y-%m-%d_%H%M') $Yo)"   # Agregar el time tag
Deb=$1 # "$DirTmp/$Pos"-Debug.log                           # Log de debug de la última ejecución

# Sincronizar a Github pages
cd $(dirname "$0")    # Cambiar al directorio de este script (está eb /bash debajo de la raiz del repo)
cd ..                 #  y subir un nivel a la raiz del repo
git add .             # Registrar todos los archivos
git commit -m "Update del $(TZ=":America/Caracas" date +'%Y-%m-%d_%H:%M')"
echo "$Yo" >> $Deb
git push -u -f origin main >> $Deb  # Usar -force para asegurar que se envíe de este servidor a github
