reptile
=======

Generates Deep Zoom Image tiles.

If the input image is JPEG and the overlap is 0, reptile uses jpegtran to avoid
lossy re-compression of the base tiles.

Status
======

Very experimental and dog slow on just about all images except for JPEG, BMP and
uncompressed TIFF, where it is just plain slow.


Dependencies
============

  * bash
  * GraphicsMagick
  * jpegtran (only needed for lossless operation)
  * OpenSeadragon (only needed for preview)

- Toke Eskildsen, te@ekot.dk
