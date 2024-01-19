#!/bin/bash

cat ./words.txt | grep "^s" | grep -v "^sa" >> output_3.txt