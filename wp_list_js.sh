#!/bin/bash

#
# Sample script for creating a .js-file of panoramas generated by wp.sh
#

ROOT=wp_pages
HEADLINE=""
DESTPREFIX=""
if [ -f wp_conf.sh ]; then
    source wp_conf.sh
fi
if [ -n "$1" ]; then                                                                                                                                                                                          DESTPREFIX="$1"
fi  
echo "var panoramas = ["
pushd "$ROOT" > /dev/null
for META in `ls */meta.dat | sort`; do
    DEST=`cat "$META" | grep dest | cut -d= -f2`
    DESCRIPTION=`cat "$META" | grep description | cut -d= -f2`
    if [ "." == ".$DEST" ]; then
        continue
    fi
    if [ "." == ".$DESCRIPTION" ]; then
        DESCRIPTION="$DEST"
    fi
    
    echo "    '$DEST',"
done
popd > /dev/null
echo "];"
