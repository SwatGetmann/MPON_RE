#include <iostream>
#include <fstream>
#include <bitset>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <iomanip>
#include <direct.h>

using namespace std;

void print_buffer(char * &buffer, int length) {
    for (int i=0; i<length; i++) {
        bitset<8> tmp(buffer[i]);
        printf("Buffer read [%d]: %d (%x)\n", i, buffer[i], tmp);
    }
}

struct wad_binary_audio {
    unsigned int size;
    unsigned short channels;
    unsigned short samplerate;
    char * binary_data;
};

#include <sstream>

namespace patch
{
    template < typename T > std::string to_string( const T& n )
    {
        std::ostringstream stm ;
        stm.fill('0');
        stm << setw(6) << n ;
        return stm.str() ;
    }
}

string generate_file_name(string dir, string pattern, string type, int index) {
    string new_file_name(dir);
    new_file_name += "\\";
    new_file_name += pattern;
    new_file_name += patch::to_string(index);
    new_file_name += type;
    return new_file_name;
}

int main() 
{
    // TODO: add a text file w/ start addresses of EACH audio block (int + hex)

    string wad_path("G:\\Games\\The Matrix - Path of Neo\\sound\\IMS\\B2_______53.WAD");
    cout << "File to open: " << wad_path << "\n";
    
    string fname_pattern("b2_53_");
    string fname_type(".bin");
    string dir_path("b2_53_extraction");
    string stats_file_name("b2_53_stats.txt");

    if (_mkdir(dir_path.c_str()) == 0)
    {
        int object_index = 0;
        wad_binary_audio * wad_chunk;

        ifstream wad_stream;
        wad_stream.open(wad_path.c_str(), ios::in|ios::binary|ios::ate);
        
        if (wad_stream.is_open()) {
            int size = wad_stream.tellg();
            printf("File Size: %d\n", size);
            wad_stream.seekg(0, ios::beg);

            bool stop_flag = false;
            ofstream new_file;
            ofstream stats_file;

            stats_file.open(stats_file_name.c_str(), ofstream::out | ofstream::trunc);

            unsigned int cur_pos = 0x0;

            while (!wad_stream.eof() || stop_flag) 
            {
                char * buffer = new char [8];
                wad_stream.read(buffer, 8);
                // print_buffer(buffer, 8);
                
                

                unsigned int object_bytesize = 0x0;
                object_bytesize = ((unsigned char)buffer[0]<<0) 
                                | ((unsigned char)buffer[1]<<8) 
                                | ((unsigned char)buffer[2]<<16) 
                                | ((unsigned char)buffer[3]<<24);
                
                if (object_bytesize == 0) {
                    stop_flag = true;
                    cout << "REACHED THE END OF WAD STREAM!" << "\n";
                    break;
                }

                cur_pos = wad_stream.tellg();
                cur_pos -= 8;
                bitset<32> cur_pos_binary(cur_pos);
                stats_file << "Block:\t" << patch::to_string(object_index) << "\t\tPosition:\t" << cur_pos << "\t" << cur_pos_binary << endl;

                unsigned short object_channels = 0x0;
                object_channels = ((unsigned char)buffer[4]<<0) 
                                | ((unsigned char)buffer[5]<<8);
                unsigned short object_samplerate = 0x0;
                object_samplerate = ((unsigned char)buffer[6]<<0) 
                                | ((unsigned char)buffer[7]<<8);

                char * object_buffer = new char [object_bytesize];
                wad_stream.read(object_buffer, object_bytesize);

                wad_chunk = new wad_binary_audio;
                wad_chunk->size = object_bytesize;
                wad_chunk->channels = object_channels;
                wad_chunk->samplerate = object_samplerate;
                wad_chunk->binary_data = object_buffer;

                // print_buffer(wad_chunk->binary_data, 0x40);

                // SAVE TO FILE
                
                string new_file_name = generate_file_name(dir_path, fname_pattern, fname_type, object_index);
                // string new_file_name = extraction_path + fname_pattern;
                // new_file_name += patch::to_string(object_index);
                // new_file_name += fname_type;
                cout << "Save to: " << new_file_name << "\n";

                new_file.open(new_file_name.c_str(), ofstream::out | ofstream::binary | ofstream::trunc);
                if (new_file.is_open())
                {
                    new_file.write((char*)&wad_chunk->size, 4);
                    new_file.write((char*)&wad_chunk->channels, 2);
                    new_file.write((char*)&wad_chunk->samplerate, 2);
                    new_file.write(wad_chunk->binary_data, wad_chunk->size);
                }
                new_file.close();
            
                object_index++;

                delete buffer;
                delete object_buffer;
                delete wad_chunk;
            }
            stats_file.close();        
        }
        wad_stream.close();
    }
    else
        cout << "THERE WAS AN ISSUE CREATING RESULT DIRECTORY! Shutting down...";

    return 0;
}