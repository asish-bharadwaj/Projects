#!/bin/bash

while read -r word
do
    if [[ $(echo "$word" | fold -w1 | sort | uniq -d) ]]
    then
        echo $word >> output_3.txt
    fi
done < ./words.txt