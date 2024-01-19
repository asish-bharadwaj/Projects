#!/bin/bash

function octtobin()
{
    num=$1 
    base=1
    while [ $num -ne 0 ]
    do
        rem=$((num%2))
        binary=$((binary+$((rem*base))))
        num=$((num/2))
        base=$((base*10))
    done
    echo $binary
}

add=$1
o1=$(echo $add | cut -d "." -f 1)
o2=$(echo $add | cut -d "." -f 2)
o3=$(echo $add | cut -d "." -f 3)
o4=$(echo $add | cut -d "." -f 4)
op1=$(octtobin $o1)
op2=$(octtobin $o2)
op3=$(octtobin $o3)
op4=$(octtobin $o4)
echo "$op1 $op2 $op3 $op4"