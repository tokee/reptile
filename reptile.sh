#!/bin/bash

TILEWIDTH=256
MARGIN=4
INPUT=""
OUTPUT=""
QUALITY=80
VERBOSITY=1
GM_ARGS="-sharpen 3"
JPEGTRAN=true

START=`date +%s`

#
# Requirements: graphicsmagic, jpegtran
#

function usage() {
    echo "Usage: ./reptile.sh [-s | -v | -V] [-h] [-w tilewidth] [-o output] [-m overlap] [-q quality] input_image"
    echo ""
    echo "If the input is a JPEG and overlap is 0, the bottom tiles are generated by lossless crop using jpegtran."
    exit 
}

# Input: message level
# Level 0: Essential, 1: Verbose, 2: Debug
function out() {
    if [ "$VERBOSITY" -ge "$2" ]; then
        echo "$1"
    fi
}

while [ ".$1" != "." ]; do
    case "$1" in
        -h)
            usage
            ;;
        -s) VERBOSITY=0 ;;
        -v) VERBOSITY=1 ;;
        -V) VERBOSITY=2 ;;
        -w)
            shift
            TILEWIDTH=$1
            ;;
        -q)
            shift
            QUALITY=$1
            ;;
        -m)
            shift
            MARGIN=$1
            ;;
        -o)
            shift
            OUTPUT=$1
            ;;
        -o)
            shift
            OUTPUT=$1
            ;;
        *)  INPUT=$1 ;;
    esac
    shift
done

if [ "." == ".$INPUT" ]; then
    usage
fi
if [ ! -f "$INPUT" ]; then
    echo "The input file '$INPUT' does not exist"$'\n'
    usage
fi

if [ "." == ".$OUTPUT" ]; then
    OUTPUT=${INPUT##*/}
    OUTPUT=${OUTPUT%.*}
fi

if [ "0" -ne `echo "$TILEWIDTH % 16" | bc` ]; then
    echo "The tile width must be evenly divisible with 16"$'\n'
    usage
fi

EXT=`echo "${INPUT##*.}" | tr '[:upper:]' '[:lower:]'`
if [ $JPEGTRAN == true ]; then
    JPEGTRAN=false
    if [ $EXT == jpg -o $EXT == jpeg ]; then
        if [ $MARGIN -eq 0 ]; then
            JPEGTRAN=true
        fi
    fi
fi

WH=`gm identify -format "%w %h" "$INPUT"`
WIDTH=`echo "$WH" | cut -d\  -f1`
HEIGHT=`echo "$WH" | cut -d\  -f2`
MAX=$((WIDTH>HEIGHT ? WIDTH : HEIGHT))
NLEVELS=`echo "l( $MAX ) / l(2)" | bc -l`
NL_WHOLE=`echo "$NLEVELS" | cut -d . -f1`
NLEVELS=`echo "if ( 2^$NL_WHOLE < $MAX ) $NL_WHOLE + 1 else $NL_WHOLE" | bc`

out "Tile width:  $TILEWIDTH pixels" 1
out "Tile margin: $MARGIN pixels" 1
out "Levels:      $NLEVELS $NLEVELS_FRAC" 1
out "Input:       $INPUT (${WIDTH}x${HEIGHT} pixels)" 1
out "Output:      $OUTPUT" 1
out "jpegtran:    $JPEGTRAN" 1

# Generate tiles
IMAGE=`mktemp --suffix=.jpg`
LEVEL=$NLEVELS
while [ $LEVEL -ge "0" ]; do
    
    TILEFOLDER="${OUTPUT}_files/$LEVEL"
    mkdir -p "$TILEFOLDER"
    if [ "$LEVEL" -eq "$NLEVELS" ]; then
        NWIDTH=$WIDTH
        NHEIGHT=$HEIGHT
        out "Level ${LEVEL}: (original image ${NWIDTH}x${NHEIGHT} pixels)" 1
        cp "$INPUT" "$IMAGE"
    else
        DIVISOR=`echo "2 ^ $((NLEVELS-LEVEL))" | bc`
#        echo "Cheese: $((NLEVELS-LEVEL)) div $DIVISOR"
        NWIDTH=$((WIDTH/DIVISOR > 0 ? WIDTH/DIVISOR : 1))
        NHEIGHT=$((HEIGHT/DIVISOR > 0 ? HEIGHT/DIVISOR : 1))
        out "Level ${LEVEL}: (downscaled image ${NWIDTH}x${NHEIGHT} pixels))" 1
        gm convert "$INPUT" $GM_ARGS -geometry "${NWIDTH}x${NHEIGHT}!" -quality $QUALITY $IMAGE
    fi

    if [ "$NWIDTH" -le "$TILEWIDTH" -a "$NHEIGHT" -le "$TILEWIDTH" ]; then
        out "  Image is ${NWIDTH}x${NHEIGHT} pixels. Using directly" 2
        mv "$IMAGE" "$TILEFOLDER/0_0.jpg"
    else        
        YTILE=0
        while [ $(( YTILE*TILEWIDTH )) -lt "$NHEIGHT" ]; do
            XTILE=0
            while [ $(( XTILE*TILEWIDTH )) -le "$NWIDTH" ]; do
                LMARGIN=$((XTILE==0 ? 0 : $MARGIN))
                TMARGIN=$((YTILE==0 ? 0 : $MARGIN))
                X=$((XTILE*TILEWIDTH-LMARGIN))
                Y=$((YTILE*TILEWIDTH-TMARGIN))
                W=$((TILEWIDTH + LMARGIN + MARGIN))
                W=$((NWIDTH-X < W ? NWIDTH-X : W))
                H=$((TILEWIDTH + TMARGIN + MARGIN))
                H=$((NHEIGHT-Y < H ? NHEIGHT-Y : H))
                
                out "  Creating tile(${XTILE}, ${YTILE})"$'\t'"pos(${X}x${Y})"$'\t'"dim(${W}x${H})" 2
                if [ "true" == "$JPEGTRAN" ]; then
                    X=$((X+LMARGIN))
                    W=$((W-LMARGIN))
                    Y=$((Y+TMARGIN))
                    H=$((H-TMARGIN))
                    COMMAND="jpegtran -optimize -crop ${W}x${H}+${X}+${Y} -copy none -outfile $TILEFOLDER/${XTILE}_${YTILE}.jpg $IMAGE"
                else 
                    COMMAND="gm convert $IMAGE -crop ${W}x${H}+${X}+${Y} -quality $QUALITY $TILEFOLDER/${XTILE}_${YTILE}.jpg"
                fi
#                echo "$COMMAND"
                bash -c "$COMMAND"
                XTILE=$((XTILE+1))
            done
            YTILE=$((YTILE+1))
        done
    fi

    LEVEL=$((LEVEL-1))
done
rm -f $IMAGE

# Generate DZI definition file
cat > ${OUTPUT}.xml << EOF
<?xml version='1.0' encoding='UTF-8'?>
<Image TileSize='$TILEWIDTH'
       Overlap='$MARGIN'
       Format='jpg'
       xmlns='http://schemas.microsoft.com/deepzoom/2008'>
    <Size Width='$WIDTH' Height='$HEIGHT'/>
</Image>
EOF

# Generate OpenSeadragon sample file
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


END=`date +%s`
out "Finished DZI tiling $INPUT in $((END-START)) seconds" 1
