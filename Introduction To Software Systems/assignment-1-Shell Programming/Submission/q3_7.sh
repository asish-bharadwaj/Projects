#!/bin/bash

cat ./words.txt | grep "a" | grep "e" | grep -v "i" >> output_3.txt