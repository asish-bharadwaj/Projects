#!/bin/bash

while IFS= read -r word
do
    string="$word"
    reverse=$(echo "$string" | rev)
    if [ "$string" == "$reverse" ]
        then
            echo "$string" >> output_3.txt
    fi
done < ./words.txt