#!/bin/bash

PROJ="projeto"

for arquivo in *; do
    
    if [ -f "$arquivo" ] && [ "$arquivo" != "$(basename "$0")" ] && [ "$arquivo" != "$PROJ" ]; then
        
		#ler qual vai ser a extensão
        ext="${arquivo##*.}"

		#Ve a extensão do arquivo cria e move 
        if [ "$ext" == "v" ]; then
			mkdir -p "$PROJ/src"
            mv "$arquivo" "$PROJ/src/"
            echo "Movido: $arquivo -> src/"

        elif [ "$ext" == "tb" ]; then
			mkdir -p "$PROJ/tb"
            mv "$arquivo" "$PROJ/tb/"
            echo "Movido: $arquivo -> tb/"

        elif [ "$ext" == "vh" ]; then
			mkdir -p "$PROJ/include"
            mv "$arquivo" "$PROJ/include/"
            echo "Movido: $arquivo -> include/"

        elif [ "$ext" == "sh" ] || [ "$ext" == "do" ] || [ "$ext" == "tcl" ]; then
			mkdir -p "$PROJ/scripts"
            mv "$arquivo" "$PROJ/scripts/"
            echo "Movido: $arquivo -> scripts/"

        elif [ "$ext" == "txt" ] || [ "$ext" == "md" ]; then
			mkdir -p "$PROJ/docs"
            mv "$arquivo" "$PROJ/docs/"
            echo "Movido: $arquivo -> docs/"
        fi
    fi
done

echo "Organização completa!"