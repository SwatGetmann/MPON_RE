import numpy as np
import matplotlib.pyplot as plt 
import pyaudio
import wave
import struct

from bitstring import BitStream, BitArray

CHUNK_SIZE = 1024
BYTE_LENGTH = 8
def read_file(path):
    stream = open(path, 'rb', buffering=CHUNK_SIZE)
    peek_result = stream.peek()
    (samples, channels, samplerate) = struct.unpack('IHH', peek_result[:8])
    print("Samples: {}\nChannels: {}\nSamplerate: {}".format(samples, channels, samplerate))
    read_data = stream.read() # first chunk
    stream.close()
    print("Length of read chunk: {}".format(len(read_data)))
    b = BitArray(read_data[0:])
    h = { 'samples': samples, 'channels': channels, 'samplerate': samplerate, 'binary': b  }
    return h

def plot(values, NFFT=512, Fs=18000, noverlap=100):
    fig, (ax1, ax2) = plt.subplots(figsize=(15, 10), nrows=2)
    plt.title("Sound Waves [Pseudo Deocded]") 
    plt.xlabel("Samples") 
    ax1.plot(values, color='b')
    Pxx, freqs, bins, im = ax2.specgram(values, NFFT=NFFT, Fs=Fs, noverlap=noverlap)
    plt.show() 
    
def factorize(stream, length, factor=4, signed=True):
    x = 0
    ratio = BYTE_LENGTH / factor
    new_values = []
    while x < (length * ratio):
        new_values.append(stream[factor*x:factor*(x+1)])
        x += 1
    if signed:
        values_to_plot = [i.int for i in new_values]
    else:
        values_to_plot = [i.uint for i in new_values]
    print("Read {} values w/ bit factor = {}".format(len(values_to_plot), factor))
    return values_to_plot
