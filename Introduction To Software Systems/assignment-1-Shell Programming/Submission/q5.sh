tree() {
    local pwd=$1
    local ind=$2
    local temp=$(basename "$pwd")
    
    for file in "$pwd"/*
    do  
        if [ -d "$file" ]
        then
            echo "$ind|__ $(basename "$file")"
            tree "$file" "$ind|  "
        else
            echo "$ind|__ $(basename "$file")"
        fi
    done


}

hidden_tree() {
    local pwd=$1
    local ind=$2
    local temp=$(basename "$pwd")
    
    shopt -s nullglob
    for file in "$pwd"/* "$pwd"/.[^.]*
    do  
        if [ -d "$file" ]
        then
            echo "$ind|__ $(basename "$file")"
            hidden_tree "$file" "$ind|  "
        else
            echo "$ind|__ $(basename "$file")"
        fi
    done
}

ascending_order(){
    local pwd=$1
    local ind=$2
    local temp=$(basename "$pwd")
    
    for file in $(ls -1 "$pwd"/*)
    do  
        if [ -d "$file" ]
        then
            echo "$ind|__ $(basename "$file")"
            tree "$file" "$ind|  "
        else
            echo "$ind|__ $(basename "$file")"
        fi
    done | sort
}

descend_order(){
    local pwd=$1
    local ind=$2
    local temp=$(basename "$pwd")
    
    shopt -s nullglob
    for file in $(ls -r "$pwd"/* | sort -r)
    do
        if [ -d "$file" ]
        then
            echo "$ind|__ $(basename "$file")"
            tree "$file" "$((ind+2))"
        else
            echo "$ind|__ $(basename "$file")"
        fi
    done
}

depth_tree() {
  local dir=$1
  local depth=$2
  local prefix=$3
  
  if [ $depth -lt 0 ]; then
    echo "Invalid depth!"
    return
  fi

  if [ -z $prefix ]; then
    prefix=""
  fi

  echo "${prefix}└── $(basename $dir)"

  if [ -d $dir ]; then
    local i=0
    local files=($(ls -1 $dir))
    local num_files=${#files[@]}
    local sub_prefix="${prefix}    "
    
    for file in ${files[@]}; do
      local path="$dir/$file"
      if [ -d $path ]; then
        if [ $i -eq $(($num_files-1)) ]; then
          echo "${prefix}    |__ $(basename $path)"
          print_tree $path $(($depth-1)) "${sub_prefix}    "
        else
          echo "${prefix}    |__ $(basename $path)"
          depth_tree $path $(($depth-1)) "${sub_prefix}|   "
        fi
      else
        if [ $i -eq $(($num_files-1)) ]; then
          echo "${prefix}    |__ $file"
        else
          echo "${prefix}    |__ $file"
        fi
      fi
      
      ((i++))
    done
  fi
}

if [ $# -eq 1 ]
then
    echo "$1"
    tree "$1" ""
    find $1 -printf '%y\n' | sort | uniq -c | awk '{printf "%d %s\n", ($2=="d")?($1-1):$1, ($2=="d")?"directories":"files"}'
else
    while getopts 'A:D:a:d:s:' OPTION
    do
        case "${OPTION}" in
        A)  
            Avalue="$OPTARG"
            echo "$Avalue"
            hidden_tree "$Avalue" ""
            find $Avalue -printf '%y\n' | sort | uniq -c | awk '{printf "%d %s\n", ($2=="d")?($1-1):$1, ($2=="d")?"directories":"files"}'
            ;;
        D)
            Dvalue="$OPTARG"
            depth_tree "$3" "$2" ""
            find $3 -printf '%y\n' | sort | uniq -c | awk '{printf "%d %s\n", ($2=="d")?($1-1):$1, ($2=="d")?"directories":"files"}'
            ;;
        a)  avalue="$OPTARG"
            echo "$avalue"
            ascending_order "$avalue" ""
            find $avalue -printf '%y\n' | sort | uniq -c | awk '{printf "%d %s\n", ($2=="d")?($1-1):$1, ($2=="d")?"directories":"files"}'
            ;;
        d)  
            dvalue="$OPTARG"
            echo "$dvalue"
            descend_order "$dvalue" ""
            find $dvalue -printf '%y\n' | sort | uniq -c | awk '{printf "%d %s\n", ($2=="d")?($1-1):$1, ($2=="d")?"directories":"files"}'
            ;;
        s)
            done
            ;;
        esac
    done
fi