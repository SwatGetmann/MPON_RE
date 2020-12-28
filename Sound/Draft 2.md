# Goal

0. Understand the structure of __FoI__ (files of insterest) & their relations
1. Sound FX + Dualogues + Cutscenes sounds extraction

# Files of interest:

<!-- * `%GAMEDIR%\sound\IMS` -->
* `%GAMEDIR%\common\Sound\NQGLOBAL_400.WAD`
* `%GAMEDIR%\common\Sound\NQGLOBAL_400.IDX`

* `%GAMEDIR%\common\Sound\NPGLOBAL_400.WAD`
* `%GAMEDIR%\common\Sound\NPGLOBAL_400.IDX`

* `%GAMEDIR%\common\Sound\NGGLOBAL_400.WAD`
* `%GAMEDIR%\common\Sound\NGGLOBAL_400.IDX`

* `%GAMEDIR%\sound\NSGLOBAL_400.WAD`

* `%GAMEDIR%\sound\NSD_EN_158.WAD`
* `%GAMEDIR%\sound\NSF_EN_158.WAD` - Streams for Film / Cinematics

* `%GAMEDIR%\sound\NS_EN_400.WAD`
* `%GAMEDIR%\sound\NL_EN_400.WAD`

* `%GAMEDIR%\sound\NP3_PSTL_*.WAD`

# Knowledge

*  `\common\Sound\NQ` is used in `CNP3::loadWADSequences()`
*  `\Sound\NSD`, `\Sound\NSF` are used in `CNP3::setLangaugeInternal()`
*  `Sound/%s.WAD` in `SX3ResourceManager::LoadClusterSound()`
*  `NSGLOBAL_400.WAD`, `NSF_EN_158.WAD`, `NSD_EN_158.WAD` files CONTAIN the bit stream data + header: <idx><channels><samplerate>
*  Streams in `NSGLOBAL_400.WAD`, `NSF_EN_158.WAD`, `NSD_EN_158.WAD` start from 196608 + 8 byte's address. Before that, the indexation + headers are provided.
*  `NP3_PSTL_*.WAD` files contains header + USHORT indexes. To which streams they are relative is UNKNOWN.
* `NSF_EN_158.WAD` is PROPERLY ALIGNED - the lenth of audio chunk is valid.
* `NSD_EN_158.WAD` is __NOT__ PROPERLY ALIGNED - the lenth of audio chunk is MORE that it's described in header.
* `NSGLOBAL_400.WAD` is PROPERLY ALIGNED - the lenth of audio chunk is valid.
* `common\Sound\*.IDX` provide indexation for `common\Sound\*.WAD` files. But the catch is that these `*.WAD`'s DO NOT HAVE BIT STREAM AUDIO DATA, only names of sounds and some other metadata.
* `NP3_PSTL_*.WAD` are related to RIMs and NIMs.
* `\sound\NSF_EN_158.WAD` - Streams for Film / Cinematics. They must be related to... files w/ Movies themselves.

* Some strange gap in `NSGLOBAL_400.WAD`, starting off last audio block @ `103954704` (`0x6323910`), Until `0x6800000`
* `NSGLOBAL_400.WAD` - some weird HEADER info (+ NAMES OF TRACKS!):
* * @ `0x6660000` - `0x6660260` 
* * @ `0x6658000` - `0x6658060`
* * @ `0x6400000` - `0x6654de0`