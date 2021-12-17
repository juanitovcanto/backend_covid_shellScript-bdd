#!/bin/bash

#----- DESCARGA Y POBLACION DE ARCHIVOS SEPARADOS EN BDD

#-----> URL: https://github.com/MinCiencia/Datos-COVID19/tree/master/output/producto2

# Variables Globales
DB_USER='juan'
DB_NAME='Covid'

DIR_C=Comunas

# Funciones

InsertarDatos(){
	ULTIMA_FECHA_BDD=$(mysql -u $DB_USER $DB_NAME -se "SELECT Fecha FROM Casos_Comunas ORDER BY Fecha DESC LIMIT 1;")
	echo Ultima fecha de casos en base de datos: $ULTIMA_FECHA_BDD

	FECHA_HOY=$(date +"%Y-%m-%d")
	if [ "$ULTIMA_FECHA_BDD" = "$FECHA_HOY" ]; then
		echo Base de datos corresponde al dia de hoy
	else
		echo Revisando Repositorios del Ministerio de Ciencias 
		FECHA_CONTADOR=$(date -I -d "1:00:00 $ULTIMA_FECHA_BDD + 1 day")
		echo fecha $FECHA_CONTADOR

		while [ "$FECHA_CONTADOR" != "$FECHA_HOY" ]; do
			if curl --output /dev/null --head --fail --silent  https://raw.githubusercontent.com/MinCiencia/Datos-COVID19/master/output/producto2/$FECHA_CONTADOR-CasosConfirmados.csv; then

				echo existe archivo del $FECHA_CONTADOR
				echo Descargando......
				wget -O $FECHA_CONTADOR.csv -q https://raw.githubusercontent.com/MinCiencia/Datos-COVID19/master/output/producto2/$FECHA_CONTADOR-CasosConfirmados.csv
				mv $FECHA_CONTADOR.csv $DIR_C/ComunasDatosSeparados/$FECHA_CONTADOR.csv

				echo Archivo $FECHA_CONTADOR.csv descargado
				awk -v fecha="$FECHA_CONTADOR" -F , '{gsub(" ","_",$6) gsub(" ","_",$3) gsub(" ","_",$2) gsub(" ","_",$1); if ($4== "") $4 = $2"000";gsub(" ","_",$4);{ for(i=1; i<=NF; i++) if($i ~ /^ *$/) $i = 0 } gsub(" ",",",$0); if(NR>1){print $4","fecha","$6}}' $DIR_C/ComunasDatosSeparados/$FECHA_CONTADOR.csv > $DIR_C/ComunasDatosSeparados/"$FECHA_CONTADOR"_sql.csv
				
				SQL_FILE_DIR=$DIR_C/ComunasDatosSeparados/"$FECHA_CONTADOR"_sql.csv
				mysql -u $DB_USER $DB_NAME << EOF
				load data local infile '$SQL_FILE_DIR' into table Casos_Comunas FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' (id_comuna,Fecha,Cantidad);
EOF
				ULTIMA_FECHA_BDD=$FECHA_CONTADOR
			else
				echo no existe archivo del $FECHA_CONTADOR
			fi
			
			FECHA_CONTADOR=$(date -I -d "1:00:00 $FECHA_CONTADOR + 1 day")
		done
	fi
	echo
	echo BASE DE DATOS actualizado a la fecha del $ULTIMA_FECHA_BDD
}

InsertarDatos
