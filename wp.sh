#!/bin/bash

#
# Sample script for using reptile to generate webpages
#
# Must have a 'web' folder containing openseadragon.min.js and 
# sub-folder 'images' with navigation-images for OpenSeadragon.
#


ROOT=wp_pages
if [ -f wp_conf.sh ]; then
    source wp_conf.sh
fi

SRC="$1"
if [ "." == ".$SRC" ]; then
    echo "Usage: ./wp.sh src dest [description]"
    exit
fi
if [ ! -f "$SRC" ]; then
    echo "Unable to locate $SRC"
    exit
fi
DEST="$2"
if [ "." == ".$DEST" ]; then
    echo "Usage: ./wp.sh src dest [description]"
    exit
fi
export DESCRIPTION="$3"

echo "Src=$SRC Desc=$DESCRIPTION Dest=$DEST"
mkdir -p "$ROOT/$DEST"
./reptile.sh -o "$DEST" "$SRC"

mv "${DEST}_files" "$ROOT/$DEST"
mv "${DEST}.html" "$ROOT/$DEST/index.html"
cp -r web/* "$ROOT/$DEST"
