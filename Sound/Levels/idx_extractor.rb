require 'pry'
require 'fileutils'

def get_idx_listing(game_dir_path)
  Dir.chdir(File.join(game_dir_path, 'sound', 'IMS'))
  Dir.glob('*').select{|fp| fp =~ /\.IDX$/ }
end

def get_wad_listing(game_dir_path)
  Dir.chdir(File.join(game_dir_path, 'sound', 'IMS'))
  Dir.glob('*').select{|fp| fp =~ /\.WAD$/ }
end

def get_ims_listing(game_dir_path)
  Dir.chdir(File.join(game_dir_path, 'common', 'Sound'))
  Dir.glob('*').select{|fp| fp =~ /\.IMS$/ }
end

def read_idx_file(idx_fp)
  rf = File.open(idx_fp, 'rb+')
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

def extract_wad_audio_blocks(idx_blocks, wad_fp, ims_metadata, extracted_dir, prefix)
  wad_rf = File.open(wad_fp, 'rb+')

  cur_index = 0
  idx_blocks.each_with_index do |block,global_index|
    wad_address = block.flatten.join.unpack("L").first
    if wad_address < 0xffffffff
      process_audio_chunk(wad_address, wad_rf, wad_fp, global_index, cur_index, extracted_dir, prefix, ims_metadata)
      cur_index += 1
    end  
  end

  wad_rf.close()
end

def detect_name_by_cur_index(cur_index, ims_metadata)
  ims_rollup = ims_metadata.each_with_object([]) do |md,a| 
    a << [(a[-1].first.to_i rescue 0) + md[:total_main], md[:name]]
    a << [(a[-1].first.to_i rescue 0) + md[:total1], md[:name] + '_b1']
    a << [(a[-1].first.to_i rescue 0) + md[:total2], md[:name] + '_b2']
    a << [(a[-1].first.to_i rescue 0) + md[:total3], md[:name] + '_b3']
    a << [(a[-1].first.to_i rescue 0) + md[:total4], md[:name] + '_b4']
  end

  if cur_index < ims_rollup[0].first
    return ims_rollup[0].last
  else
    ims_rollup.each_cons(2) do |md1, md2|
      return md2.last if cur_index >= md1.first && cur_index < md2.first
    end
  end
end

def process_audio_chunk(wad_address, wad_rf, wad_fp, global_index, cur_index, extracted_dir, prefix, ims_metadata)
  puts "[#{global_index} | #{int_to_le_hex(global_index)}] [#{cur_index}] #{wad_address} | #{int_to_le_hex(wad_address)}" 
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
  
  name = detect_name_by_cur_index(cur_index, ims_metadata)
  
  save_path = File.join(extract_wad_dir, "#{prefix}_#{'%04i' % global_index}__#{name}_#{'%04i' % cur_index}.wav")
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

def match_idx_wad_ims(idx_fp_listing, wad_fp_listing, ims_fp_listing)
  idx_prefixes = idx_fp_listing.map{|s| s[/_(B.*)\.IDX/,1]}
  wad_prefixes_indexes = wad_fp_listing.map{|s| s[/(B.*)\.WAD/,1].gsub(/_{2,}/,'_')}.each_with_index.to_a
  ims_prefixes_indexes = ims_fp_listing.map{|s| s[/(B.*)\.IMS/,1].gsub(/_{2,}/,'_')}.each_with_index.to_a

  result_hash = {}
  idx_prefixes.each_with_index do |idx_prefix, i|
    wad_match = wad_prefixes_indexes.find{|wad_prefix,_| wad_prefix == idx_prefix}
    ims_match = ims_prefixes_indexes.find{|ims_prefix,_| ims_prefix == idx_prefix}

    result_hash[idx_prefix] = {
      idx_fp: File.join('.', 'sound', 'IMS', idx_fp_listing[i]),
      wad_fp: File.join('.', 'sound', 'IMS', wad_fp_listing[wad_match.last]),
      ims_fp: File.join('.', 'common', 'Sound', ims_fp_listing[ims_match.last]),
    }
  end
  result_hash
end

def extract_ims_metadata(ims_fp)
  ims_rf = File.open(ims_fp, 'rb+')
  i_total_fsize = ims_rf.read(4).unpack('L').first
  i_total_metadata_blocks = ims_rf.read(4).unpack('L').first
  ims_rf.seek(12, IO::SEEK_CUR) # jump to str

  md = [] # md for metadata

  last_index = 0
  i_total_metadata_blocks.times do |i|
    a_name = ims_rf.read(0x20).unpack('Z'*0x20)
    a_name_di = a_name.each_with_index.find{|c,i| c == ''}.last
    name = a_name[0..a_name_di].join
    puts name
    i_u1, i_u2, i_u3, i_total_main_audio_blocks = ims_rf.read(0x10).unpack('L'*4)
    a1, total1, a2, total2, a3, total3, a4, total4 = ims_rf.read(0x20).unpack('L'*8)
    md << {
      name: name,
      total_main: i_total_main_audio_blocks,
      total1: total1,
      total2: total2,
      total3: total3,
      total4: total4
    }
    last_index += i_total_main_audio_blocks + total1 + total2 + total3 + total4
  end
  puts "{#{File.basename(ims_fp)}} #{md.pretty_inspect}"
  ims_rf.close()

  md
end

extracted_dir = "F:\\22 Code Playground\\Matrix PON Reverse Engineering\\Sound\\Levels\\ExtractedNames"
FileUtils.mkdir_p(extracted_dir)

game_dir_path = "g:\\Games\\The Matrix - Path of Neo"
idx_fp_listing = get_idx_listing(game_dir_path)
wad_fp_listing = get_wad_listing(game_dir_path)
ims_fp_listing = get_ims_listing(game_dir_path)

Dir.chdir(game_dir_path)
idx_wad_map = match_idx_wad_ims(idx_fp_listing, wad_fp_listing, ims_fp_listing)

idx_wad_map.each do |prefix, fp_hash|
  idx_fp = fp_hash[:idx_fp]
  wad_fp = fp_hash[:wad_fp]
  ims_fp = fp_hash[:ims_fp]

  puts "Reading: #{idx_fp}..."
  idx_file_contents = read_idx_file(idx_fp)
  puts "Total IDX file size: #{idx_file_contents.size}"
  idx_parsed_res = parse_idx_file(idx_file_contents)

  ims_metadata = extract_ims_metadata(ims_fp)
  
  puts "WAD file: #{wad_fp}"
  extract_wad_audio_blocks(idx_parsed_res[:blocks], wad_fp, ims_metadata, extracted_dir, prefix)
end