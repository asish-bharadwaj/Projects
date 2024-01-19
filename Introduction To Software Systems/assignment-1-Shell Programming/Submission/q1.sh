#!/bin/bash

echo "Enter Name: "
read name
echo "Enter DOB: "
read dob
readarray -d " " -t DoB<<<"$dob"
declare -i months=${DoB[0]}
months=$((12-months))
months+=$(date '+%m')
months+=$((12*$(($(($(date +'%Y')-1))-${DoB[1]}))))
echo "Hello $name, your age is $months months."
