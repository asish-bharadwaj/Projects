#!/bin/bash

input="$1"
output="$2"
while read -r word
do
   if [ $(echo $word | wc -m) -ge 4 ]
   then
      echo $word >> $output
   fi
done < $input