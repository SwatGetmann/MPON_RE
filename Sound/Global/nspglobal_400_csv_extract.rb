require 'csv'
require 'pry'
require 'fileutils'

def read_name(file_io, length=0x20)
  a_name = file_io.read(length).unpack('Z'*length)
  a_name_di = a_name.each_with_index.find{|c,i| c == ''}.last
  name = a_name[0..a_name_di].join
  puts name
  return name
end

def read_wad_block(wad_rf)
  wad_info = { pos: wad_rf.pos }
  header_index, _flag = wad_rf.read(4).unpack('SS')
  name = read_name(wad_rf)
  wad_info[:name] = name
  wad_info[:header_index] = header_index
  size, _ = wad_rf.read(0x1C).unpack('C'*0x1C)
  wad_info[:size] = size
  wad_info[:audio_blocks] = []
  size.times do |i|
    audio_block_index, _ = wad_rf.read(4+9*2+4+2*3).unpack('L'+'S'*9+'L'+'S'*3)
    puts "WAD.pos : #{wad_rf.pos} | #{audio_block_index}"
    wad_info[:audio_blocks] << audio_block_index
  end
  wad_info
end

# ruby 'F:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\nspglobal_400_csv_extract.rb' 'g:\Games\The Matrix - Path of Neo' 'f:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\TEST_NSGlobal400'

game_dir_path = ARGV[0]
extract_path = ARGV[1]

puts "Game Dir Path: {#{game_dir_path}}"
puts "Extraction Path : {#{extract_path}}"

FileUtils.mkdir_p(extract_path)

idx_fp = File.join(game_dir_path,'common', 'Sound', 'NPGLOBAL_400.IDX')
wad_fp = File.join(game_dir_path,'common', 'Sound', 'NPGLOBAL_400.WAD')

# read indexes
puts "Reading: #{idx_fp} [indexes] ..."
puts "Reading: #{wad_fp} [indexes] ..."

wad_headers_array = []
global_idx = 0

idx_rf = File.open(idx_fp, 'rb+')
wad_rf = File.open(wad_fp, 'rb+')

total = idx_rf.read(4).unpack('L').first

while global_idx < total
  addr1 = idx_rf.read(4).unpack('L').first
  if addr1 != 4294967295
    wad_rf.seek(addr1, IO::SEEK_SET)
    wad_block = read_wad_block(wad_rf)
    puts wad_block
    wad_headers_array << wad_block
    # binding.pry if global_idx % 10 == 0
  end
  global_idx += 1
end

idx_rf.close()
wad_rf.close()

audio_block_table = []
wad_headers_array.sort_by{|x| x[:pos]}.each do |wdh|
  wdh[:audio_blocks].each do |wab|
    audio_block_table << {
      'audio_block_index': wab, 
      'header_name': wdh[:name], 
      'header_index': wdh[:header_index], 
      'header_pos': wdh[:pos]
    }
  end
end

csv_fp = File.join(extract_path, 'result_table_full.csv')

CSV.open(csv_fp, 'w+') do |csv|
  csv << ['Audio Block Index', 'Header Name', 'Header Index', 'Header Position']
  audio_block_table.each do |abt|
    csv << abt.values
  end
end

csv_fp = File.join(extract_path, 'result_table_nodup.csv')

CSV.open(csv_fp, 'w+') do |csv|
  csv << ['Audio Block Index', 'Header Name', 'Header Index', 'Header Position']
  audio_block_table.group_by{|x| x[:audio_block_index]}.map{|_,v| v.first }.each do |abt|
    csv << abt.values
  end
end

puts "CSVs SAVED!"