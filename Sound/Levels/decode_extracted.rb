require 'pry'
require 'fileutils'

decoder_tool_path = "F:\\22 Code Playground\\Matrix PON Reverse Engineering\\Sound\\Levels\\XboxADPCM.exe"

extracted_dir_path = "F:\\22 Code Playground\\Matrix PON Reverse Engineering\\Sound\\Levels\\Extracted"
Dir.chdir(extracted_dir_path)
dir_listing = Dir.glob('*')

puts dir_listing
if dir_listing.any?
	dir_listing.each do |dir_path|
		puts "Processing dir: #{dir_path}..."
		wav_fp_listing = Dir.glob(File.join(dir_path)+'/*').select{|s| s=~/\.wav$/i}
		puts "Total blocks: #{wav_fp_listing.size}"

		decoded_dir_path = File.join(Dir.pwd, dir_path, "decoded")
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

