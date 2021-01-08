# The Matrix: Path of Neo (PC) - Reverse Engineering

## Premise
The project's goal is to extract as much data from The Matrix: Path of Neo (MPON) as possible.

## Folders & their meanings
* `3D Models` - for tools that extract 3d models data. \
Status: __NOT YET STARTED__
* `010 Templates` - useful templates for 010 Hex Editor. \
Status: __ONLY RECENT ONES, TO BE ADDED__
* `Historical` - historical subfolders w/ older 010 templates and stuff.
* `Jupyter Notebooks` - old notebooks used for analysis of what type of audio is stored in audio extracted bitstream.
* `Other` - notes on undocumented game mechanics.
* `Process Monitor Replays` - PLM log files, used as a source of file read offset that is helpful when building 010 Templates.
* `Sound` - tools for extracting audio data. \
Status: __FINISHED, NEED REFACTORING__
* `Subtitles` - extracting subtitles data (so-called 'Louie' files). \
Status: __NOT YET STARTED__
* `Textures` - extracting textures data. \
Status: __NOT YET STARTED__
## Version Log
v1.0.0 - Sound Extraction: done, named files are provided.

## Goals

0. 010 Hex Editor templates for the main types of packages. \
Subgoal. The map / wiki of types presented
1. CLI/GUI tool for extracting sounds, music, textures, subtitles, 3d models
2. CLI/GUI tool to repair some of the textures
3. Global Connection map (of all game file formats)

## Challenges
The hardest tasks are to extract:
* __audio__, \
as it is stored in byte format, that is not known to be easily decoded. \
-> IT's XBOX ADPCM! (because NoisePilot3 source files that can be seen in .bin file say so) \
-> Yet I have to convert it to the final file to decode DURING extraction

* __textures__, \
as they are stored in somewhat similar to DXT1/DXT5 formats, \
but there was no extraction done to check it

* __3d models__, \
as I have no idea how they can be decoded

* __gameplay mechanics__, \
as they (+configs) are all stored in *.bin format, that is not decoded. \
-> Only Ghidra can help here.

## TODO
### YouTube Playlist
1. GHIDRA footage: restoring strings connections
2. MatrixConfig.ini - FARCLIPBIAS footage
3. Audio Extraction process: \
3.1. Previous attempts + issues of unknown decoding \
3.2. Finding correct decoding + Final extraction \
3.3. Connection map of audio files
## Author
Swat Getmann