# Thoughts

1. Try different ffmpeg codecs w/ Matrix PON audio... \
Maybe something will eventually work with the presented bytestream.

2. Audacity -> RAW Stream -> 8bit unsigned PCM, 44100 -> playable similar to music stream, but heavily compressed & distorted by the encoding/compression algorithm. 

3. Try decode in linux ... \
https://gavv.github.io/articles/decode-play/

4. The audio is encdoed w/ smth called 'NoisePilot3'... or at least this tool is needed in order to run chunks of it - as discovered by checking strings in Matrix3W32S.bin

# 2020-12-19, Results

1. Started analysis of 1 chanel audio - dialogues from NSD_EN_158.WAD file. \
Also made a Audacity comparison, that showed we need SIGNED pcm representation. \
Tried to visualize the bitstream in Jupyter - see Jupyter Notebooks/Dialogue Parser.ipynb for details. \
The result is that 4bits unsigned give CLEARER spectrogram than 8bits ...

2. Factors like 2,1 do not help

# 2020-12-19, TODO

* Test ADPCM decoding...

### IMA ADPCM Decoding Result:
Failed - it provides inbareable noise instead of sound.
Even seeing it w/ spectrogramm does not help.

# 2020-12-25 - 2020-12-26, Result

XBOX ADPCM WORKS! \
It provides both stereo & mono decoding well enough for dialogues & music chunks I've got.

## TODO: 

Short-term:
* Patch current extractor (for b2_53) so it writes a RIFF header - so the bit stream can leter be decoded via XboxADPCM.exe

Long-term: 
* Write extractor for level-based audio ()
* Add ADPCM conversion INTO extractor