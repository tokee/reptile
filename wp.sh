#!/bin/bash

#
# Sample script for using reptile to generate webpages
#
# Must have a 'web' folder containing openseadragon.min.js and 
# sub-folder 'images' with navigation-images for OpenSeadragon.
#

WEBROOT="/pano"
ROOT=wp_pages
if [ -f wp_conf.sh ]; then
    source wp_conf.sh
fi

SRC="$1"
if [ "." == ".$SRC" ]; then
    echo "Usage: ./wp.sh src dest [description]"
    exit 2
fi
if [ ! -f "$SRC" ]; then
    echo "Unable to locate $SRC"
    exit 3
fi
DEST="$2"
if [ "." == ".$DEST" ]; then
    echo "Usage: ./wp.sh src dest [description]"
    exit 4
fi
OUT="$ROOT/$DEST"
export DESCRIPTION="$3"

if [ -d "$OUT" ]; then
    echo "Error: Destination '$OUT' already exists"
    exit 5
fi
if [[ -z "$(which vips)" ]]; then
    echo "vips not available: Using (slow) GraphicsMagic tile generation"
    VIPS=false
else
    echo "vips available: Tile generation will be fast"
    VIPS=true
fi

snippet() {
    echo ""
    echo "<br/>"
    if [ "." == ".$DESCRIPTION" ]; then
        echo "<span class=\"pano\"><a href=\"$WEBROOT/$DEST/\">[panorama]</a></span>"
    else
        echo "<span class=\"pano\"><a href=\"$WEBROOT/$DEST/\" title=\"$DESCRIPTION\">[panorama]</a></span>"
    fi
    echo ""
}

echo "Src=${SRC}, Dest=${OUT}, Description=${DESCRIPTION}"
snippet
mkdir -p "$OUT"
if [[ "true" == "$VIPS" ]]; then
    ./reptile_vips.sh "$SRC" "$DEST"
else
    ./reptile.sh -o "$DEST" "$SRC"
fi    

mv "${DEST}.xml" "${DEST}_files" "$OUT/"
mv "${DEST}.html" "$OUT/index.html"
if [ -d web ]; then
    cp -r web/* "$OUT"
fi
echo "src=$SRC" > "$OUT/meta.dat"
echo "dest=$DEST" >> "$OUT/meta.dat"
echo "description=$DESCRIPTION" >> "$OUT/meta.dat"
echo "date=`date +%Y%m%d-%H%M`" >> "$OUT/meta.dat"

# Triggers
if [ -f wp_list.sh ]; then
    ./wp_list.sh > "$ROOT/panoramas.html"
    ./wp_list.sh "./" > "$ROOT/panoramas_noroot.html"
fi
if [ -f wp_list_js.sh ]; then
    ./wp_list_js.sh > "$ROOT/panoramas_list.js"
fi
if [ -f total.sh ]; then
    ./total.sh > "$ROOT/mp.txt"
fi
snippet
