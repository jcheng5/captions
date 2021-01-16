# Automatically generate caption videos from .srt files

Requires `ffmpeg` to be installed and on the path.

1. Add .srt files to `data/` subdirectory
2. Run `make`
3. If you get an error about "durations table is not up-to-date", edit data/000-durations.csv and change any 00:00 times to the duration (in mm:ss) of the original video, then run `make` again

Output files will be written in .mp4 format in the `data/` subdirectory.

If you get an error about text being clipped, edit the .srt in question so that the text is not so long (i.e. add a hard wrap) and retry.
