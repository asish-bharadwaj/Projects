#!/bin/bash

input="$1"
output="$2"
while read -r word
do
    if echo "$word" | grep -q -v j
    then
        echo $word >> $output
    fi
done < $input