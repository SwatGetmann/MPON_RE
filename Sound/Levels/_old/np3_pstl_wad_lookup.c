#include <stdio.h>
#include <stdlib.h>
#include <Windows.h>

struct testStruct {
    unsigned int total_size;
    unsigned short * offsets;
};

int main()
{
    struct testStruct storage;

    unsigned char buffer1[4];
    const char *filename1 = "G:\\playground\\RE Matrix Path Of Neo\\TEST_c_wad_extractor\\NP3_PSTL_Start_Menu.WAD";
    const char *filename2 = "G:\\playground\\RE Matrix Path Of Neo\\TEST_c_wad_extractor\\NP3_PSTL_RIMXRayDestruct.WAD";
    const char *filename3 = "G:\\playground\\RE Matrix Path Of Neo\\TEST_c_wad_extractor\\NP3_PSTL_B13_Sky_Neo_Wins_Deck.WAD";

    FILE *ptr = fopen(filename1, "rb");

    fread(buffer1, sizeof(buffer1), 1, ptr);

    storage.total_size = 0x0;
    storage.total_size += buffer1[0] | (buffer1[1]<<8) | (buffer1[2]<<16) | (buffer1[3]<<24);

    printf("The read `buffer1` value -~ TOTAL: %d\n", storage.total_size);

    size_t buffer_malloc_size = storage.total_size * sizeof(unsigned char) * 2;
    unsigned char * buffers = malloc(buffer_malloc_size);  // 2 for conversion to short
    fread(buffers, buffer_malloc_size, 1, ptr);

    storage.offsets = malloc(storage.total_size * sizeof(unsigned short));

    int i;
    for (i = 0; i < storage.total_size; i++)
    {
        storage.offsets[i] = 0x0;
        storage.offsets[i] += buffers[2*i + 0] | (buffers[2*i + 1] << 8);
    }

    for (i = 0; i < storage.total_size; i++)
    {
        printf("offsets[%d] := %d\n", i, storage.offsets[i]);
    }

    // free(offsets);
    free(buffers);
    free(ptr);

    return 0;
}