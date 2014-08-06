#!/bin/bash


WIDTH=512
INPUT=""
OUTPUT=""

function usage() {
    echo "Usage: ./reptile.sh [-w tilewidth] [-o output] input_image"
    exit 
}

while [ ".$1" != "." ]; do
    if [ ".$1" == ".-w" ]; then
        shift
        WIDTH=$1
        shift
    fi

    if [ ".$1" == ".-o" ]; then
        shift
        OUTPUT=$1
        shift
    fi

    if [ ".$1" != "." ]; then
        INPUT=$1
        shift
    fi
done

if [ "." == ".$INPUT" ]; then
    usage
fi

if [ "." == ".$OUTPUT" ]; then
    OUTPUT=${INPUT##*/}
    OUTPUT=${OUTPUT%.*}
fi

if [ "0" -ne `echo "$WIDTH % 16" | bc` ]; then
    echo "The tile width must be evenly divisible with 16"$'\n'
    usage
fi

echo "Tile width: $WIDTH"
echo "Input:      $INPUT"
echo "Output:     $OUTPUT"
