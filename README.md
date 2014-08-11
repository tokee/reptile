reptile
=======

Generates Deep Zoom Image tiles with a sample presentation page.

Deep Zoom Image (DZI) tiles are used together with software such as
OpenSeadragon (http://openseadragon.github.io/) to provide seamless
zooming of large images on the web. DZI-tiles are static image files
that can served from any webserver.

DZI can be seen as a pyramid with the original image at the bottom,
the image scaled to 25% (50% horizontally and 50% vertically) on top
of that, scaled to 6.25% (25% horizontally and 25% vertically) on top
of that and so forth, until the topmost image is a single pixel. Each
layer is split into tiles, typically 256x256 or 512x512 pixels, with
an optional overlap to compensate for visual errors due to rounding.

reptile is limited in scope and slower that similar tools, such as
http://search.cpan.org/~drrho/Graphics-DZI-0.05/script/deepzoom
http://libvips.blogspot.dk/

reptile's claim to fame is that JPEG tiles for the bottom layer can
be generated without loss of quality from a JPEG source, under the
constriction that the overlap between tiles is 0.


Status
======

Seems to work, but not very fast.

The lossless base tile generation is especially slow. For a sample 
image of 32 MPixels, a full non-lossless run took 43 seconds and a 
run with lossless base-tiles took 93 seconds (the deepzoom Perl 
script took 7 seconds).


Dependencies
============

  * bash
  * GraphicsMagick
  * jpegtran (only needed for lossless operation)
  * OpenSeadragon (only needed for preview)

- Toke Eskildsen, te@ekot.dk
