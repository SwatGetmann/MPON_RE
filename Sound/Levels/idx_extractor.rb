require 'pry'
require 'fileutils'

extracted_dir = "F:\\22 Code Playground\\Matrix PON Reverse Engineering\\Sound\\Levels\\Extracted"
FileUtils.mkdir_p(extracted_dir)

ims_dir_path = "g:\\Games\\The Matrix - Path of Neo\\sound\\IMS\\";
Dir.chdir(ims_dir_path)
idx_fp_listing = Dir.glob('*').select{|fp| fp =~ /\.IDX$/ }
puts idx_fp_listing

tfp = idx_fp_listing[0]
rf = File.open(tfp, 'rb+')
full_file = rf.read()
rf.close()

puts full_file.size

total_count = full_file[0..3].unpack('L')
puts total_count
split_file = full_file[4..-1].chars.each_slice(4)
puts split_file.size

def int_to_le_hex(int)
  return [int].pack('L').chars.map{|b| '%02X' % b.ord }.join(' ')
end

# split_file.each_with_index do |tmp,i|
#     unpacked_value = tmp.flatten.join.unpack("L").first
#     puts "[#{i}|#{int_to_le_hex(i)}] #{unpacked_value}|#{int_to_le_hex(unpacked_value)}" if unpacked_value < 0xffffffff
# end

lvl_wad_fp_listing = Dir.glob('*').select{|fp| fp =~ /\.WAD$/ }
puts lvl_wad_fp_listing

twfp = lvl_wad_fp_listing.first
rf = File.open(twfp, 'rb+')

def process_audio_chunk(tmp, i, unpacked_value, rf, extracted_dir)
  puts "[#{i}|#{int_to_le_hex(i)}] #{unpacked_value}|#{int_to_le_hex(unpacked_value)}" 
  rf.seek(unpacked_value, IO::SEEK_SET)

  s_size = rf.read(4)
  s_channels = rf.read(2)
  s_samplerate = rf.read(2)
  
  i_size = s_size.unpack('L').first
  i_channels = s_channels.unpack('S').first
  i_samplerate = s_samplerate.unpack('S').first

  s_stream = rf.read(i_size)

  puts "Size: #{i_size}\nChannels: #{i_channels}\nSamplerate: #{i_samplerate}\n"

  save_path = File.join(extracted_dir, "test_file_#{'%03i' % i}.wav")

  sf = File.open(save_path, 'wb+')
  sf.write('RIFF')
  sf.write([i_size + 36].pack('L'))
  sf.write('WAVE')
  
  sf.write('fmt ')
  sf.write([20].pack('L')) # chunkSize
  sf.write([105].pack('S')) # wFormatTag
  sf.write([i_channels].pack('S')) # channels
  sf.write([i_samplerate].pack('L')) # samplerate
  sf.write([54000].pack('L')) # avgBytesPerSec
  sf.write([i_channels * 36 ].pack('S')) # blockAlign
  sf.write([4].pack('S')) # bitsPerSample
  sf.write([4194306].pack('L')) # unknown
  
  sf.write('fact')
  sf.write([4].pack('L')) # chunksize
  sf.write([209152].pack('L')) # uncompressedSize

  sf.write('data')
  sf.write([i_size].pack('L')) # chunkSize
  sf.write(s_stream)

  sf.close()

  puts "Extracted to: #{save_path}!"
end

split_file.each_with_index do |tmp,i|
  # break if i > 4
  unpacked_value = tmp.flatten.join.unpack("L").first
  if unpacked_value < 0xffffffff
    process_audio_chunk(tmp, i, unpacked_value, rf, extracted_dir)
  end  
end

rf.close()

Dir.chdir(extracted_dir)
extracted_listing = Dir.glob('*')
extracted_listing.each do |efp|
  cmd = "'XboxADPCM.exe' #{efp}"
  puts cmd
  `#{cmd}`
end