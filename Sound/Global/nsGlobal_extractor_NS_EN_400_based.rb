require 'pry'
require 'fileutils'
require 'csv'

module MPONExtract
  OVERFLOW_VALUE = 0xFFFFFFFF

  def self.save_wav(path, size, channels, samplerate, stream)
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
  
  def self.read_audio_block_data(fp)
    puts "Reading: #{fp} [AUDIO BLOCK DATA CSV] ..."
    csv_data = CSV.read(fp)
    adb_data = csv_data[1..-1].map { |a| { :adb_index => a[0].to_i, :header_name => a[1], :header_idx => a[2].to_i, :header_pos => a[3].to_i } }
    adb_data.sort_by!{ |x| x[:adb_index] }
    adb_data
  end
  
  def self.read_ns_es_400_offsets(fp)
    puts "Reading: #{fp} [NS_EN_400 OFFSETS] ..."
    ns_en_total = 0
    ns_en_offsets = []
    ns_en_idx = 0
    ns_en_rf = File.open(fp, 'rb+')
    ns_en_total = ns_en_rf.read(4).unpack('L').first
    ns_en_total.times do |ns_en_idx|
      ns_en_offset = ns_en_rf.read(4).unpack('L').first
      if ns_en_offset != OVERFLOW_VALUE
        ns_en_offsets << { id: ns_en_idx, offset: ns_en_offset }
        puts "#{'%05i' % ns_en_idx}: #{ns_en_offset}"
      end
    end
    ns_en_rf.close()
    puts "[NS_EN_400 OFFSETS] are read!"
    ns_en_offsets
  end


  def self.read_merge_wad_fp_headers(ns_en_offsets, wad_fp)
    wad_basename = File.basename(wad_fp)
    wad_name = wad_basename.gsub(/\.WAD$/, '')
    
    puts "Reading: #{wad_fp} [#{wad_name} HEADERS] ..."
    global_idx = 0
    
    wad_rf = File.open(wad_fp, 'rb+')
    _, offset = wad_rf.read(8).unpack('LL')
    while wad_rf.pos - 8 < offset
      b_sample = wad_rf.read(4).unpack('L').first
      while b_sample == OVERFLOW_VALUE
        b_sample = wad_rf.read(4).unpack('L').first
        next
      end
      if b_sample >= 0 && wad_rf.pos-4 < offset + 8
        header_addr = wad_rf.pos-4
        size, channels, samplerate = wad_rf.read(8).unpack('LSS')
        # "HEADER: [<inner_header_idx> | <global_idx>] : <address> , <audio_signature>"
        puts "HEADER: [#{b_sample} | #{global_idx}] : #{header_addr} , {#{size} , #{channels}, #{samplerate/1000.0}k}"
    
        offset_hash = ns_en_offsets.find{|h| h[:id] == b_sample}
        if offset_hash
          offset_hash.merge!({ 
            header_idx: b_sample,
            global_idx: global_idx,
            header_addr: header_addr,
            size: size,
            channels: channels,
            samplerate: samplerate,
            source: wad_basename,
            found: false
          })
        else
          puts "NOT FOUND OFFSET HASH FOR ID: #{b_sample}"
          binding.pry
        end
        global_idx += 1
      else 
        break
      end
      
    end
    wad_rf.close()
    puts "="*100
  end


  def self.extract_streams_wad_fp(ns_en_offsets, wad_fp, adb_data, extract_path, msg)
    wad_basename = File.basename(wad_fp)
    wad_name = wad_basename.gsub(/\.WAD$/, '')

    puts "START EXTRACTING [#{wad_basename}] #{msg} ..."
    wad_rf = File.open(wad_fp, 'rb+')
    nsglobal_headers = ns_en_offsets.select{|r| r.keys.include?(:source) && r[:source] == wad_basename}
    puts "TOTAL ADB: #{nsglobal_headers.size}"
    nsglobal_headers.each do |nsg_header|
      puts "[#{nsg_header[:source]}] EXTRACTING: #{nsg_header[:id]} @ #{nsg_header[:offset]} {#{nsg_header[:size]} , #{nsg_header[:channels]} , #{nsg_header[:samplerate]}}"
      adb_block = adb_data.find{|r| r[:adb_index] == nsg_header[:id]}
      if adb_block
        puts "NAME: #{adb_block[:header_name]}"

        wad_rf.seek(nsg_header[:offset]+8, IO::SEEK_SET)
        stream = wad_rf.read(nsg_header[:size])
        nsg_header[:found] = true

        save_path = File.join(extract_path, "#{wad_name}__#{'%05i' % nsg_header[:id]}__#{adb_block[:header_name]}.wav")
        save_wav(save_path, nsg_header[:size], nsg_header[:channels], nsg_header[:samplerate], stream)
        puts "Stream read & saved. Position: #{wad_rf.pos}"
      else
        puts "ADB BLOCK NOT FOUND!"
        binding.pry
      end
    end
    wad_rf.close()
    puts "FINISHED EXTRACTING [NSF_EN_158.WAD] !"
  end

  def self.extract_streams_nsglobal_400(ns_en_offsets, wad_fp, adb_data, extract_path)
    puts "START EXTRACTING [NSGLOBAL_400.WAD] - SFX + Additional Music ..."
    wad_rf = File.open(wad_fp, 'rb+')
    nsglobal_headers = ns_en_offsets.select{|r| r.keys.include?(:source) && r[:source] == 'NSGLOBAL_400.WAD'}
    puts "TOTAL ADB: #{nsglobal_headers.size}"
    nsglobal_headers.each do |nsg_header|
      puts "[#{nsg_header[:source]}] EXTRACTING: #{nsg_header[:id]} @ #{nsg_header[:offset]} {#{nsg_header[:size]} , #{nsg_header[:channels]} , #{nsg_header[:samplerate]}}"
      adb_block = adb_data.find{|r| r[:adb_index] == nsg_header[:id]}
      if adb_block
        puts "NAME: #{adb_block[:header_name]}"

        wad_rf.seek(nsg_header[:offset]+8, IO::SEEK_SET)
        stream = wad_rf.read(nsg_header[:size])
        nsg_header[:found] = true

        save_path = File.join(extract_path, "NSGLOBAL_400__#{'%05i' % nsg_header[:id]}__#{adb_block[:header_name]}.wav")
        save_wav(save_path, nsg_header[:size], nsg_header[:channels], nsg_header[:samplerate], stream)
        puts "Stream read & saved. Position: #{wad_rf.pos}"
      else
        puts "ADB BLOCK NOT FOUND!"
        binding.pry
      end
    end
    wad_rf.close()
    puts "FINISHED EXTRACTING [NSGLOBAL_400.WAD] !"
  end

  def self.extract_streams_nsf_en_158(ns_en_offsets, wad_fp, adb_data, extract_path)
    puts "START EXTRACTING [NSF_EN_158.WAD] - Video Mixes ..."
    wad_rf = File.open(wad_fp, 'rb+')
    nsglobal_headers = ns_en_offsets.select{|r| r.keys.include?(:source) && r[:source] == 'NSF_EN_158.WAD'}
    puts "TOTAL ADB: #{nsglobal_headers.size}"
    nsglobal_headers.each do |nsg_header|
      puts "[#{nsg_header[:source]}] EXTRACTING: #{nsg_header[:id]} @ #{nsg_header[:offset]} {#{nsg_header[:size]} , #{nsg_header[:channels]} , #{nsg_header[:samplerate]}}"
      adb_block = adb_data.find{|r| r[:adb_index] == nsg_header[:id]}
      if adb_block
        puts "NAME: #{adb_block[:header_name]}"

        wad_rf.seek(nsg_header[:offset]+8, IO::SEEK_SET)
        stream = wad_rf.read(nsg_header[:size])
        nsg_header[:found] = true

        save_path = File.join(extract_path, "NSF_EN_158__#{'%05i' % nsg_header[:id]}__#{adb_block[:header_name]}.wav")
        save_wav(save_path, nsg_header[:size], nsg_header[:channels], nsg_header[:samplerate], stream)
        puts "Stream read & saved. Position: #{wad_rf.pos}"
      else
        puts "ADB BLOCK NOT FOUND!"
        binding.pry
      end
    end
    wad_rf.close()
    puts "FINISHED EXTRACTING [NSF_EN_158.WAD] !"
  end

  def self.extract_streams_nsd_en_158(ns_en_offsets, wad_fp, adb_data, extract_path)
    puts "START EXTRACTING [NSD_EN_158.WAD] - Dialogues + Voices ..."
    wad_rf = File.open(wad_fp, 'rb+')
    nsglobal_headers = ns_en_offsets.select{|r| r.keys.include?(:source) && r[:source] == 'NSD_EN_158.WAD'}
    puts "TOTAL ADB: #{nsglobal_headers.size}"
    nsglobal_headers.each do |nsg_header|
      puts "[#{nsg_header[:source]}] EXTRACTING: #{nsg_header[:id]} @ #{nsg_header[:offset]} {#{nsg_header[:size]} , #{nsg_header[:channels]} , #{nsg_header[:samplerate]}}"
      adb_block = adb_data.find{|r| r[:adb_index] == nsg_header[:id]}
      if adb_block
        puts "NAME: #{adb_block[:header_name]}"

        wad_rf.seek(nsg_header[:offset]+8, IO::SEEK_SET)
        stream = wad_rf.read(nsg_header[:size])
        nsg_header[:found] = true

        save_path = File.join(extract_path, "NSD_EN_158__#{'%05i' % nsg_header[:id]}__#{adb_block[:header_name]}.wav")
        save_wav(save_path, nsg_header[:size], nsg_header[:channels], nsg_header[:samplerate], stream)
        puts "Stream read & saved. Position: #{wad_rf.pos}"
      else
        puts "ADB BLOCK NOT FOUND!"
        binding.pry
      end
    end
    wad_rf.close()
    puts "FINISHED EXTRACTING [NSD_EN_158.WAD] !"
  end

end

# ruby 'F:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\nsGlobal_extractor_NS_EN_400_based.rb' 'g:\Games\The Matrix - Path of Neo' 'f:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\ExtractNSGlobal_Namings' 'F:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\NPGlobal400_CSV\result_table_full.csv'

game_dir_path = ARGV[0]
extract_path = ARGV[1]
csv_index_path = ARGV[2]

puts "Game Dir Path: {#{game_dir_path}}"
puts "Extraction Path : {#{extract_path}}"
puts "CSV Index Path : {#{csv_index_path}}"

adb_data = MPONExtract::read_audio_block_data(csv_index_path)

FileUtils.mkdir_p(extract_path)

wad_fp = File.join(game_dir_path,'sound', 'NSGLOBAL_400.WAD')
d_wad_fp = File.join(game_dir_path,'sound', 'NSD_EN_158.WAD')
f_wad_fp = File.join(game_dir_path,'sound', 'NSF_EN_158.WAD')
ns_en_fp = File.join(game_dir_path,'sound', 'NS_EN_400.IDX')

ns_en_offsets = MPONExtract::read_ns_es_400_offsets(ns_en_fp)

MPONExtract::read_merge_wad_fp_headers(ns_en_offsets, wad_fp)
MPONExtract::read_merge_wad_fp_headers(ns_en_offsets, d_wad_fp)
MPONExtract::read_merge_wad_fp_headers(ns_en_offsets, f_wad_fp)

MPONExtract::extract_streams_wad_fp(ns_en_offsets, wad_fp, adb_data, extract_path, 'SFX + Additional Music')
MPONExtract::extract_streams_wad_fp(ns_en_offsets, f_wad_fp, adb_data, extract_path, 'Movies Mixes')
MPONExtract::extract_streams_wad_fp(ns_en_offsets, d_wad_fp, adb_data, extract_path, 'Dialogues, Vocals')