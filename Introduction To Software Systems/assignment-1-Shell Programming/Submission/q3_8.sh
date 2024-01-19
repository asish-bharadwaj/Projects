#!/bin/bash

cat ./words.txt | grep -e "^a" -e "^e" -e "^i" -e "^o" -e "^u" | grep -v -e "a$" -e "e$" -e "i$" -e "o$" -e "u$" >> output_3.txt
