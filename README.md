# Automatically generate caption videos from .srt files

Requires `ffmpeg` to be installed and on the path. (On macOS, `brew install ffmpeg` should do it)

1. Add .srt files to `data/` subdirectory.
2. Run `make`.
    * This will give you an error about "durations table is not up-to-date". Edit data/000-durations.csv and change any 00:00 times to the duration (in mm:ss) of the original video.
3. Run `make` again, it will actually do stuff this time.

Output files will be written in .mp4 format in the `data/` subdirectory.

If you get an error about text being clipped, edit the .srt in question so that the text is not so long (i.e. add a hard wrap) and retry.

## Checking results

You can use [VLC](https://www.videolan.org/vlc/index.html) to play the generated .mp4 file; if the .srt file is still next to it, you should see captions from both the .mp4 and from VLC, and they should exactly match.
