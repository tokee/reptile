#!/bin/bash

#
# Requirements: vips
#

TILEWIDTH=256
MARGIN=0
QUALITY=85
if [ -f reptile_conf.sh ]; then
    source reptile_conf.sh
fi
INPUT="$1"
OUTPUT="$2"

START=`date +%s`

function usage() {
    echo "Usage: ./reptile_vips.sh input_image dest_folder"
    exit  $1
}

if [[ -z "$(which vips)" ]]; then
    >&2 echo "Error: 'vips' not available"$'\n'
    usage 5
fi
if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
    echo "Please provide input image and output folder"$'\n'
    usage 6
fi
if [ ! -f "$INPUT" ]; then
    >&2 echo "The input file '$INPUT' does not exist"$'\n'
    usage 7
fi
if [ "." == ".$OUTPUT" ]; then
    OUTPUT=${INPUT##*/}
    OUTPUT=${OUTPUT%.*}
fi
if [[ -d "${OUTPUT}_files" ]]; then
    >&2 echo "The output folders for '$OUTPUT' already exist"$'\n'
    usage 8
fi

WH=`identify -format "%w %h" "$INPUT"`
WIDTH=`echo "$WH" | cut -d\  -f1`
HEIGHT=`echo "$WH" | cut -d\  -f2`
MAX=$((WIDTH>HEIGHT ? WIDTH : HEIGHT))
NLEVELS=`echo "l( $MAX ) / l(2)" | bc -l`
NL_WHOLE=`echo "$NLEVELS" | cut -d . -f1`
NLEVELS=`echo "if ( 2^$NL_WHOLE < $MAX ) $NL_WHOLE + 1 else $NL_WHOLE" | bc`

echo "Levels:      $NLEVELS $NLEVELS_FRAC" 1
echo "Input:       $INPUT (${WIDTH}x${HEIGHT} pixels)" 1
echo "Output:      $OUTPUT" 1
echo "jpegtran:    $JPEGTRAN" 1

# Generation time

# https://www.libvips.org/API/current/Making-image-pyramids.html

vips dzsave --tile-size=$TILEWIDTH --overlap=$MARGIN  "$INPUT" "$OUTPUT" --suffix .jpg[Q=90]
cp "${OUTPUT}.dzi" "${OUTPUT}.xml"

# http://stackoverflow.com/questions/14434549/how-to-expand-shell-variables-in-a-text-file
# Input: template-file
function ctemplate() {
    TMP="`mktemp`.sh"
    echo 'cat <<END_OF_TEXT' >  $TMP
    cat  "$1"                >> $TMP
    echo 'END_OF_TEXT'       >> $TMP
    . $TMP
    rm $TMP
}

# Generate OpenSeadragon sample file
if [ -f "template.html" ]; then
    ctemplate "template.html" > ${OUTPUT}.html
else 
cat > ${OUTPUT}.html << EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- Download at http://github.com/openseadragon/openseadragon/releases/download/v1.0.0/openseadragon-bin-1.0.0.zip" -->
    <script src="openseadragon.min.js"></script>
</head>
<body>
<h1>OpenSeadragon enabled $INPUT</h1>
<div id="zoom-display" class="openseadragon" style="border: 1px solid black; width: 100%; height: 800px;">
<script type="text/javascript">
    myDragon = OpenSeadragon({
    id:            "zoom-display",
    maxZoomLevel: 64,

    tileSources: {
        Image: {        
            xmlns: "http://schemas.microsoft.com/deepzoom/2008",
            Url: "${OUTPUT}_files/",
            Format:   "jpg",
            Overlap:  "$MARGIN",
            TileSize: "$TILEWIDTH",
            Size: {
                Width:  "$WIDTH",
                Height: "$HEIGHT"
            }
        }
    },
    });
</script>
</div>
</body>
</html>
EOF
fi

END=`date +%s`
echo "Finished generating $TILECOUNT DZI tiles from $INPUT in $((END-START)) seconds" 1
