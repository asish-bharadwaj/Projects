#!/bin/bash

while read -r word
do
    if echo "$word" | grep -q -i -E '[^aeiou]{3}'
    then
        echo "$word" >> output_3.txt
    fi
done < ./words.txt
