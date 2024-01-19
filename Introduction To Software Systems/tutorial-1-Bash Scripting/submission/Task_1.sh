#!/bin/bash

function gcd() 
{
    if [ $1 -le $2 ]
    then
        a=$1
        b=$2
    else
        a=$2
        b=$1
    fi
    # Using Euclid's GCD Algorithm.
    while [ $a -ne 0 ]
    do
        c=$a
        a=$((b % a))
        b=$c
    done
    echo "GCD: $b"
}

function lcm ()
{
    a=$1
    b=$2
    if [ $a -gt $b ]
    then
        c=$a 
    else
        c=$b 
    fi
    while [ $((c % a)) -ne 0 ] || [ $((c % b)) -ne 0 ]
    do
        c=$((c+1))
    done
    echo "LCM: $c"
}

gcd "$@"
lcm "$@"