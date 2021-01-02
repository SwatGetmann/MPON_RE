require 'pry'
require 'fileutils'

# ruby 'F:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Levels\decode_extracted.rb' 'F:\22 Code Playground\Matrix PON Reverse Engineering\Sound\Global\ExtractNSD'

decoder_tool_path = "F:\\22 Code Playground\\Matrix PON Reverse Engineering\\Sound\\Levels\\XboxADPCM.exe"

extracted_dir_path = if ARGV[0]
	ARGV[0]
else
	"F:\\22 Code Playground\\Matrix PON Reverse Engineering\\Sound\\Levels\\Extracted"
end

puts "USING dir {#{extracted_dir_path}} data"
puts "External Deocder: {#{decoder_tool_path}}"

Dir.chdir(extracted_dir_path)
dir_listing = Dir.glob('*')

puts dir_listing
if dir_listing.any?
	dir_listing.each do |dir_path|
		if dir_path =~ /\.wav$/
			decoded_dir_path = File.join(Dir.pwd, "decoded")
			puts "Create Dir: {#{decoded_dir_path}}"
			FileUtils.mkdir_p(decoded_dir_path) unless Dir.exist?(decoded_dir_path)

			wav_fp = dir_path
			puts "Processing file: #{dir_path}..."

			abs_wav_fp = File.join(Dir.pwd, wav_fp)
			decoded_wav_fp = File.join(decoded_dir_path, File.basename(wav_fp).gsub('.wav','_pcm.wav'))
			decode_cmd = "'#{decoder_tool_path}' '#{abs_wav_fp}' '#{decoded_wav_fp}'"
			# puts decode_cmd
			%x{ "#{decoder_tool_path}" "#{abs_wav_fp}" "#{decoded_wav_fp}"}

		elsif Dir.exist?(dir_path)
			puts "Processing dir: #{dir_path}..."
			wav_fp_listing = Dir.glob(File.join(dir_path)+'/*').select{|s| s=~/\.wav$/i}
			puts "Total blocks: #{wav_fp_listing.size}"

			decoded_dir_path = File.join(Dir.pwd, dir_path, "decoded")
			puts "Create Dir: {#{decoded_dir_path}}"
			FileUtils.mkdir_p(decoded_dir_path)

			wav_fp_listing.each do |wav_fp|
				abs_wav_fp = File.join(Dir.pwd, wav_fp)
				decoded_wav_fp = File.join(decoded_dir_path, File.basename(wav_fp).gsub('.wav','_pcm.wav'))
				decode_cmd = "'#{decoder_tool_path}' '#{abs_wav_fp}' '#{decoded_wav_fp}'"
				# puts decode_cmd
				%x{ "#{decoder_tool_path}" "#{abs_wav_fp}" "#{decoded_wav_fp}"}
			end

			puts "Dir #{dir_path} processed!"
		end
	end
end

