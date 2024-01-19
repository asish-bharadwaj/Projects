#!/bin/bash

input="$1"
output="$2"
declare -A groups

while read -r word
do
    vowel_count=$(echo $word | grep -o -i "[aeiou]" | wc -l)
    groups[$vowel_count]+="$word\n"
done < $input

for ((i=0; i<${#groups[@]}; i++))
do
    if [[ "${groups[i]}" ]]
    then
        continue
    fi
    echo -e "${groups[$i]}"| sort >> $output
done