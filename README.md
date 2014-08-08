reptile
=======

Generates Deep Zoom Image tiles with a sample presentation page.

If the input image is JPEG and the overlap is 0, reptile uses jpegtran to avoid
lossy re-compression of the base tiles.

Status
======

Seems to work, but not very fast.

The lossless base tile generation is especially slow. For a sample image of 32 MPixels,
a full non-lossless run took 31 seconds and a run with lossless base-tiles took 75 
seconds (the deepzoom Perl script took 4 seconds).


Dependencies
============

  * bash
  * GraphicsMagick
  * jpegtran (only needed for lossless operation)
  * OpenSeadragon (only needed for preview)

- Toke Eskildsen, te@ekot.dk
