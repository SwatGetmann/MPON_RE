require 'pry'
require 'fileutils'

def save_wav(path, size, channels, samplerate, stream)
  sf = File.open(path, 'wb+')
  sf.write('RIFF')
  sf.write([size + 36].pack('L'))
  sf.write('WAVE')
  
  sf.write('fmt ')
  sf.write([20].pack('L')) # chunkSize
  sf.write([105].pack('S')) # wFormatTag
  sf.write([channels].pack('S')) # channels
  sf.write([samplerate].pack('L')) # samplerate
  sf.write([54000].pack('L')) # avgBytesPerSec
  sf.write([channels * 36 ].pack('S')) # blockAlign
  sf.write([4].pack('S')) # bitsPerSample
  sf.write([4194306].pack('L')) # unknown
  
  sf.write('fact')
  sf.write([4].pack('L')) # chunksize
  sf.write([209152].pack('L')) # uncompressedSize

  sf.write('data')
  sf.write([size].pack('L')) # chunkSize
  sf.write(stream)

  sf.close()
end

# ruby 'F:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\NSD_Global_extractor.rb' 'g:\Games\The Matrix - Path of Neo' 'f:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\ExtractNSD'

game_dir_path = ARGV[0]
extract_path = ARGV[1]

puts "Game Dir Path: {#{game_dir_path}}"
puts "Extraction Path : {#{extract_path}}"

FileUtils.mkdir_p(extract_path)

wad_fp = File.join(game_dir_path,'sound', 'NSD_EN_158.WAD')

# read indexes
puts "Reading: #{wad_fp} ..."

headers_array = []
stream_array = []
global_idx = 0

wad_rf = File.open(wad_fp, 'rb+')
_, offset = wad_rf.read(8).unpack('LL')
while wad_rf.pos - 8 < offset
  b_sample = wad_rf.read(4).unpack('L').first
  while b_sample == 4294967295
    b_sample = wad_rf.read(4).unpack('L').first
    next
  end
  if b_sample >= 0 && wad_rf.pos-4 < offset + 8
    header_addr = wad_rf.pos-4
    size, channels, samplerate = wad_rf.read(8).unpack('LSS')
    # "HEADER: [<inner_header_idx> | <global_idx>] : <address> , <audio_signature>"
    puts "HEADER: [#{b_sample} | #{global_idx}] : #{header_addr} , {#{size} , #{channels}, #{samplerate/1000.0}k}"
    headers_array << { 
      header_idx: b_sample,
      global_idx: global_idx,
      header_addr: header_addr,
      size: size,
      channels: channels,
      samplerate: samplerate,
      found: false
    }
    global_idx += 1
  else 
    break;
  end
end

puts "="*100

last_stream_end_pos = 0

wad_rf.seek(0x38000, IO::SEEK_SET) # skip dumb zeros

while global_idx > 0
  if wad_rf.pos % 16 != 0
    new_addr = (wad_rf.pos / 16.0).ceil * 16
    puts "Jump to: #{new_addr}"
    wad_rf.seek()
  end
  b_sample, _channels, _samplerate = wad_rf.read(8).unpack('LSS')
  # binding.pry
  next if b_sample == 0
  # binding.pry if wad_rf.pos >= 0xCC00000
  binding.pry if global_idx == 6074 && wad_rf.pos == 388424
  if headers_array.select{|x| !x[:found] && (x[:size] == b_sample && x[:channels] == _channels && x[:samplerate] == _samplerate) }.any?
    header = headers_array.select{|x| !x[:found]}.find{|h| h[:size] == b_sample}

    if wad_rf.pos != last_stream_end_pos
      puts "Skipped #{wad_rf.pos - last_stream_end_pos} bytes!"
    end

    stream_addr = wad_rf.pos-8
    # _channels, _samplerate = wad_rf.read(4).unpack('SS')
    puts "STREAM: [#{header[:header_idx]} | #{header[:global_idx]}] : #{stream_addr} , {#{header[:size]}, #{header[:channels]}, #{header[:samplerate]}}. Left to find: #{global_idx - 1}"

    stream = wad_rf.read(header[:size])
    header[:found] = true

    binding.pry if global_idx % 10 == 0

    save_path = File.join(extract_path, "NSD_EN_158__#{'%04i' % header[:global_idx]}_#{header[:header_idx]}.wav")
    save_wav(save_path, header[:size], header[:channels], header[:samplerate], stream)
    last_stream_end_pos = wad_rf.pos
    puts "Stream read & saved. Position: #{last_stream_end_pos}"

    global_idx -= 1
  else
    wad_rf.seek(-4, IO::SEEK_CUR)
  end
end

wad_rf.close()

puts "FINISHED EXTRACTING!"