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

* `%GAMEDIR%\sound\NSGLOBAL_400.WAD` - In-Game Cinematics / Music / SFX + Headers

* `%GAMEDIR%\sound\NSD_EN_158.WAD`
* `%GAMEDIR%\sound\NSF_EN_158.WAD` - Streams for Film / Cinematics

* `%GAMEDIR%\sound\NS_EN_400.WAD`
* `%GAMEDIR%\sound\NL_EN_400.WAD`

* `%GAMEDIR%\sound\NP3_PSTL_*.WAD` - relative to RIM/NIMs

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
* Some strange gap in `NSGLOBAL_400.WAD`, starting off last audio block @ `209004920` (`0xC752978`), Until `0xCC00000`
* Gap in `NSGLOBAL_400.WAD`, @ `0x12C00000` - Until `0x13000000`
* Some strange audio in `NSGLOBAL_400.WAD`, audio block @ `313949052` (`0x12B67B7C`). It repeats 3 times, thoough 2 time NOT BROKEN: @ `0x13000000`, @ `0x23460000`
* Audio issues in `NSGLOBAL_400.WAD`, @ `419262560` (`0x18FD7060`) - start of header @ `0x19000000` - `0x19400000`
* Audio issues in `NSGLOBAL_400.WAD`, @ `522452460` (`0x1F23FDEC`) - start of header @ `0x1F400000` - `0x1F800000`

* `NSGLOBAL_400.WAD` - some weird HEADER info (+ NAMES OF TRACKS!):

* * @ `0x6400000` - `0x6654de0` (`0x0`,         + 2444768 bytes, `0x254DE0`)
* * @ `0x6658000` - `0x6658060` (`0x258000`,    +, `0x60`)
* * @ `0x6660000` - `0x6660260` (`0x260000`,    +, `0x260`)

* * @ `0xC800000` - `0xCA54DE0`
* * @ `0xCA58000` - `0xCA58060`
* * @ `0xCA60000` - `0xCA60260`

* * @ `0x12C00000` - `0x12E54DE0`
* * @ `0x12E58000` - `0x12E58060`
* * @ `0x12E60000` - `0x12E60260`

* * @ `0x19000000` - `0x19254DE0`
* * @ `0x19258000` - `0x19258060`
* * @ `0x19260000` - `0x19260260`

* * @ `0x1F400000` - `0x1F654DE0`
* * @ `0x1F658000` - `0x1F658060`
* * @ `0x1F660000` - `0x1F660260`

* (?) NSGLOBAL Headers (0x400000) may refer to the exact order STREAM data is stored, not labeled in the beginning header... \ 
That is yet to be checked.

* `NP3_PSTL` files refer to Gap-Header in `NSGLOBAL_400.WAD`
* Good examples: `Katana`, `MX_B2_` (`I_Say.WAD`). Gap-Headers in NSGlobal have DIFFERENT values in the first block - or at least the names are different ... \
And these indexes are either the previous or following to the ones from `NP3_PSTL`...