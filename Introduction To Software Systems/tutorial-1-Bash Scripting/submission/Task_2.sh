#!/bin/bash

touch output1.txt
cal > output1.txt
date +'%Y-%m-%d' >> output1.txt
for ((i=0; i<100; i++))
do
    echo "ISS is cool" >> output1.txt
done
cat output1.txt
head -n 3 output1.txt
head -n 15 output1.txt | tail -n +6
sed -n '=' output1.txt | tail -n 1
echo "I'm UG1" >> output1.txt
wc -w output1.txt | cut -d " " -f 1
echo "I'm studying ISS" >> output1.txt
cut -d " " -f 4 output1.txt
cut -d " " -f 2,3,4,5 output1.txt
l=$( sed -n '=' output1.txt | tail -n 1 )
cut -d " " -f 3 output1.txt | head -n $((l-5))
cut -d " " -f 2,4 output1.txt