#!/bin/bash

input="$1"
output="$2"
tr '[:upper:]' '[:lower:]' < $input | shuf >> $output