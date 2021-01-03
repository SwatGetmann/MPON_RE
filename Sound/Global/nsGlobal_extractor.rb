require 'pry'
require 'fileutils'
require 'csv'

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

def handle_broken_block()
  # TBD
end

# ruby 'F:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\nsGlobal_extractor.rb' 'g:\Games\The Matrix - Path of Neo' 'f:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\ExtractNSGlobal_TESTNames' 'F:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\TEST_NSGlobal400\result_table_nodup.csv'

game_dir_path = ARGV[0]
extract_path = ARGV[1]
csv_index = ARGV[2]

puts "Game Dir Path: {#{game_dir_path}}"
puts "Extraction Path : {#{extract_path}}"
puts "CSV Index Path : {#{csv_index}}"

csv_data = CSV.read(csv_index)
adb_data = csv_data[1..-1].map{|a| {:adb_index => a[0].to_i, :header_name => a[1], :header_idx => a[2].to_i, :header_pos => a[3].to_i}}

FileUtils.mkdir_p(extract_path)

wad_fp = File.join(game_dir_path,'sound', 'NSGLOBAL_400.WAD')

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

total = global_idx

puts "="*100

while global_idx > 0 && (total - global_idx) < 300
  b_sample = wad_rf.read(4).unpack('L').first
  next if b_sample == 0
  # binding.pry if wad_rf.pos >= 0xCC00000
  if headers_array.select{|x| !x[:found]}.map{|h| h[:size]}.include?(b_sample)
    stream_addr = wad_rf.pos-4
    header = headers_array.select{|x| !x[:found]}.find{|h| h[:size] == b_sample}
    _channels, _samplerate = wad_rf.read(4).unpack('SS')
    puts "STREAM: [#{header[:header_idx]} | #{header[:global_idx]}] : #{stream_addr} , {#{header[:size]}, #{header[:channels]}, #{header[:samplerate]}}. IDX: #{total - global_idx}. Left to find: #{global_idx - 1}"

    # CHANGE to HANLDE BROKEN BLOCK

    if stream_addr == 103954704
      puts "Fucked up DATA CHUNK shit"
      length_to_read = 0x6400000 - wad_rf.pos

      stream = wad_rf.read(length_to_read)
      header[:found] = false
      save_path = File.join(extract_path, "NSGLOBAL_400__#{'%04i' % header[:global_idx]}_#{header[:header_idx]}_false_stream.wav")
      save_wav(save_path, length_to_read, header[:channels], header[:samplerate], stream)
      puts "Stream read & saved (though FALSE). Position: #{wad_rf.pos}"
      # global_idx -= 1

      puts "!!! MOVE TO A VALID NEW ADDRESSS!"
      new_addr = 0x6800000
      wad_rf.seek(new_addr, IO::SEEK_SET)
      next
    end

    if stream_addr == 209004920
      puts "FUCKED UP block x2"

      # STREAM: [5769 | 3035] : 209004920 , {1679832, 2, 22000}. Left to find: 2726
      # Stream read & saved. Position: 210684760

      length_to_read = 0xC800000 - wad_rf.pos

      stream = wad_rf.read(length_to_read)
      header[:found] = false
      save_path = File.join(extract_path, "NSGLOBAL_400__#{'%04i' % header[:global_idx]}_#{header[:header_idx]}_false_stream.wav")
      save_wav(save_path, length_to_read, header[:channels], header[:samplerate], stream)
      puts "Stream read & saved (though FALSE). Position: #{wad_rf.pos}"
      # global_idx -= 1

      puts "!!! MOVE TO A VALID NEW ADDRESSS!"
      new_addr = 0xCC00000
      wad_rf.seek(new_addr, IO::SEEK_SET)
      next
    end

    if stream_addr == 313949052
      puts "Strange block x3"

      length_to_read = 0x12C00000 - wad_rf.pos

      stream = wad_rf.read(length_to_read)
      header[:found] = false
      save_path = File.join(extract_path, "NSGLOBAL_400__#{'%04i' % header[:global_idx]}_#{header[:header_idx]}_false_stream.wav")
      save_wav(save_path, length_to_read, header[:channels], header[:samplerate], stream)
      puts "Stream read & saved (though FALSE). Position: #{wad_rf.pos}"
      # global_idx -= 1

      puts "!!! MOVE TO A VALID NEW ADDRESSS!"
      new_addr = 0x13000000
      wad_rf.seek(new_addr, IO::SEEK_SET)
      next
    end

    if stream_addr == 419262560
      puts "Strange block x4"

      length_to_read = 0x19000000 - wad_rf.pos

      stream = wad_rf.read(length_to_read)
      header[:found] = false
      save_path = File.join(extract_path, "NSGLOBAL_400__#{'%04i' % header[:global_idx]}_#{header[:header_idx]}_false_stream.wav")
      save_wav(save_path, length_to_read, header[:channels], header[:samplerate], stream)
      puts "Stream read & saved (though FALSE). Position: #{wad_rf.pos}"
      # global_idx -= 1

      puts "!!! MOVE TO A VALID NEW ADDRESSS!"
      new_addr = 0x19400000
      wad_rf.seek(new_addr, IO::SEEK_SET)
      next
    end

    if stream_addr == 522452460
      puts "Strange block x5"

      length_to_read = 0x1F400000 - wad_rf.pos

      stream = wad_rf.read(length_to_read)
      header[:found] = false
      save_path = File.join(extract_path, "NSGLOBAL_400__#{'%04i' % header[:global_idx]}_#{header[:header_idx]}_false_stream.wav")
      save_wav(save_path, length_to_read, header[:channels], header[:samplerate], stream)
      puts "Stream read & saved (though FALSE). Position: #{wad_rf.pos}"
      # global_idx -= 1

      puts "!!! MOVE TO A VALID NEW ADDRESSS!"
      new_addr = 0x1F800000
      wad_rf.seek(new_addr, IO::SEEK_SET)
      next
    end

    stream = wad_rf.read(header[:size])
    header[:found] = true

    binding.pry if (total - global_idx) == 0


    save_path = File.join(extract_path, "NSGLOBAL_400__#{'%04i' % (total - global_idx)}__#{'%04i' % header[:global_idx]}_#{header[:header_idx]}__#{adb_data[total - global_idx][:header_name]}_#{adb_data[total - global_idx][:adb_index]}.wav")
    save_wav(save_path, header[:size], header[:channels], header[:samplerate], stream)
    puts "Stream read & saved. Position: #{wad_rf.pos}"

    global_idx -= 1
  end
end

wad_rf.close()

puts "FINISHED EXTRACTING!"