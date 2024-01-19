#!/bin/bash

while getopts ":C:" OPTION
do
    case "${OPTION}" in
      C)
        case $OPTARG in
            insert)
                flag=1
                while getopts ":f:l:n:o:" option
                do
                    case $option in
                    f)  
                        fname=$OPTARG
                        if $(grep -q "^${fname}." contacts.csv) 
                        then
                            echo "Unable to insert contact!."
                            flag=0
                            break
                        fi
                        ;;
                    l)
                        lname=$OPTARG
                        ;;
                    n)
                        contact=$OPTARG
                        ;;
                    o)
                        company=$OPTARG
                        ;;
                    esac
                done
                if [ $flag -eq 1 ]
                then
                    echo "$fname,$lname,$contact,$company" >> contacts.csv
                fi
                ;;
            edit)
                while getopts ":k:f:l:n:o:" option
                do
                    case $option in
                    k)
                        fname=$OPTARG
                        line=$(grep -no "$fname" contacts.csv | cut -f1 -d:)
                        lname=$(cut -d ',' -f2 contacts.csv | sed -n "${line}p")
                        contact=$(cut -d ',' -f3 contacts.csv | sed -n "${line}p")
                        company=$(cut -d ',' -f4 contacts.csv | sed -n "${line}p")
                        ;;
                    f)
                        new_fname=$OPTARG
                        sed -i "s/$fname/$new_fname/" contacts.csv
                        ;;
                    l)
                        new_lname=$OPTARG
                        sed -i "$line s/$lname/$new_lname/" contacts.csv
                        ;;
                    n)
                        new_contact=$OPTARG
                        sed -i "$line s/$contact/$new_contact/" contacts.csv
                        ;;
                    o)
                        new_company=$OPTARG
                        sed -i "$line s/$company/$new_company/" contacts.csv
                        ;;
                    esac
                done
                ;;
            display)
                if [ $# -eq 2 ]
                then    
                    cat contacts.csv
                else
                while getopts ":ad" option
                do
                    case $option in
                        a) order="asc";;
                        d) order="dec";;
                    esac
                    if [ "$order" == "asc" ]
                    then
                        command="sort -t ',' -k1"
                        heading=$(head -n 1 contacts.csv)
                        content=$(tail -n+2 contacts.csv | eval $command)
                    elif [ "$order" == "dec" ]
                    then
                        command="sort -t ',' -k1r"
                        heading=$(head -n 1 contacts.csv)
                        content=$(tail -n+2 contacts.csv | eval $command)
                    fi
                    echo "$heading"
                    echo "$content"
                done
                fi
                ;;
            search)
                    while getopts ":c:v:" option 
                    do
                        case $option in
                        c) column="$OPTARG";;
                        v) value="$OPTARG";;
                        esac
                    done

                    case $column in
                        fname) col=1 ;;
                        lname) col=2 ;;
                        mobile) col=3 ;;
                        office) col=4 ;;
                    esac
                    heading=$(head -n 1 contacts.csv)
                    
                ;;
            delete)  
                while getopts :k: option
                do
                    case $option in
                    k)   
                    fname=$OPTARG                                    
                    line=$(grep -no "$fname" contacts.csv | cut -f1 -d:)
                    sed -i "${line}d" contacts.csv
                    ;;
                    esac
                done
        esac 
    esac
done