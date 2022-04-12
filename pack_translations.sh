#!/usr/bin/env bash
#https://github.com/hhyyrylainen/GodotPckTool/releases

for folder in ./Translations/*; do
    if [ -d "$folder" ]; then
        folder=$(basename $folder)
        folder="${folder##*/}"
        if [ $folder = "export" ]; then
            echo ""
        else
            echo "$folder"
            rm ./Translations/export/$folder.pck
            for file in ./Translations/$folder/*.import
            do
                echo "$file"
                importfile1=${file:2}
                importfile2=`grep -o 'res[^"]*' "$file" | head -1`
                importfile2=${importfile2:6}
                ./godotpcktool --pack "./Translations/export/$folder.pck" --action add --file "$importfile1"
                ./godotpcktool --pack "./Translations/export/$folder.pck" --action add --file "$importfile2"
            done
            for file in ./Translations/$folder/*.tres
            do
                echo "$file"
                ./godotpcktool --pack "./Translations/export/$folder.pck" --action add --file "${file:2}"
            done
        fi
    fi
done