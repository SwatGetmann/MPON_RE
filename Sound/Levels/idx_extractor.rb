require 'pry'
require 'fileutils'

def get_idx_listing(game_dir_path)
  Dir.chdir(game_dir_path)
  Dir.glob('*').select{|fp| fp =~ /\.IDX$/ }
end

def get_wad_listing(game_dir_path)
  Dir.chdir(game_dir_path)
  Dir.glob('*').select{|fp| fp =~ /\.WAD$/ }
end

def read_idx_file(idx_file_path)
  rf = File.open(idx_file_path, 'rb+')
  contents = rf.read()
  rf.close()
  contents
end

def parse_idx_file(contents)
  total_count = contents[0..3].unpack('L').first
  puts "Total audio blocks: #{total_count}" 
  blocks = contents[4..-1].chars.each_slice(4)
  puts "Total split 4 byte blocks: #{blocks.size}"
  {
    total: total_count,
    blocks: blocks
  }
end

def int_to_le_hex(int)
  return [int].pack('L').chars.map{|b| '%02X' % b.ord }.join
end

def extract_wad_audio_blocks(idx_blocks, wad_fp, extracted_dir, prefix)
  wad_rf = File.open(wad_fp, 'rb+')

  idx_blocks.each_with_index do |block,j|
    wad_address = block.flatten.join.unpack("L").first
    if wad_address < 0xffffffff
      process_audio_chunk(wad_address, wad_rf, wad_fp, j, extracted_dir, prefix)
    end  
  end

  wad_rf.close()
end

def process_audio_chunk(wad_address, wad_rf, wad_fp, index, extracted_dir, prefix)
  puts "[#{index} | #{int_to_le_hex(index)}] #{wad_address} | #{int_to_le_hex(wad_address)}" 
  wad_rf.seek(wad_address, IO::SEEK_SET)

  s_size = wad_rf.read(4)
  s_channels = wad_rf.read(2)
  s_samplerate = wad_rf.read(2)
  
  i_size = s_size.unpack('L').first
  i_channels = s_channels.unpack('S').first
  i_samplerate = s_samplerate.unpack('S').first

  s_stream = wad_rf.read(i_size)

  puts "Size: #{i_size}\nChannels: #{i_channels}\nSamplerate: #{i_samplerate}\n"
  
  extract_wad_dir = File.join(extracted_dir, prefix)
  FileUtils.mkdir_p(extract_wad_dir)
  save_path = File.join(extract_wad_dir, "#{prefix}_#{'%03i' % index}.wav")
  save_wav(save_path, i_size, i_channels, i_samplerate, s_stream)
  puts "Extracted to: #{save_path}!"
end

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

def match_idx_wad(idx_fp_listing, wad_fp_listing)
  idx_prefixes = idx_fp_listing.map{|s| s[/_(B.*)\.IDX/,1]}
  wad_prefixes_indexes = wad_fp_listing.map{|s| s[/(B.*)\.WAD/,1].gsub(/_{2,}/,'_')}.each_with_index.to_a
  result_hash = {}
  idx_prefixes.each_with_index do |idx_prefix, i|
    wad_match = wad_prefixes_indexes.find{|wad_prefix,_| wad_prefix == idx_prefix}
    result_hash[idx_prefix] = {
      idx_fp: idx_fp_listing[i],
      wad_fp: wad_fp_listing[wad_match.last]
    }
  end
  result_hash
end

extracted_dir = "F:\\22 Code Playground\\Matrix PON Reverse Engineering\\Sound\\Levels\\Extracted"
FileUtils.mkdir_p(extracted_dir)

game_dir_path = "g:\\Games\\The Matrix - Path of Neo\\sound\\IMS\\"
idx_fp_listing = get_idx_listing(game_dir_path)
wad_fp_listing = get_wad_listing(game_dir_path)

idx_wad_map = match_idx_wad(idx_fp_listing, wad_fp_listing)

idx_wad_map.each do |prefix, fp_hash|
  idx_fp = fp_hash[:idx_fp]
  wad_fp = fp_hash[:wad_fp]

  puts "Reading: #{idx_fp}..."
  idx_file_contents = read_idx_file(idx_fp)
  puts "Total IDX file size: #{idx_file_contents.size}"
  idx_parsed_res = parse_idx_file(idx_file_contents)
  
  puts "WAD file: #{wad_fp}"
  extract_wad_audio_blocks(idx_parsed_res[:blocks], wad_fp, extracted_dir, prefix)
end

# Dir.chdir(extracted_dir)
# extracted_listing = Dir.glob('*')
# extracted_listing.each do |efp|
#   cmd = "'XboxADPCM.exe' #{efp}"
#   puts cmd
#   `#{cmd}`
# end