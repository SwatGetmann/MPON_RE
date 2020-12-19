# The Matrix: Path of Neo (PC) - Reverse Engineering

## Premise
The project's goal is to extract as much data from MPON as possible. \

## Version
v0.0.1

## Goals

* Goal #0: \
010 Hex Editor templates for the main types of packages
* Goal #0.5: \
The map / wiki of types presented
* Goal #1: \
CLI/GUI tool for extracting sounds, music, textures, subtitles, 3d models
* Goal #2: \
CLI/GUI tool to repair some of the textures

## Challenges
The hardest task is to extract:
* audio, \
as it is stored in byte format, that is not known to be easily decoded
* textures, \
as they are stored in somewhat similar to DXT1/DXT5 formats, \
but there was no extraction done to check it
* 3d models, \
as I have no idea how they can be decoded
* gameplay mechanics, \
as they (+configs) are all stored in *.bin format, that is not decoded

## Author
Swat Getmann