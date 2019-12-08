config_path = ARGV[0]
# puts "config_path: #{config_path}"
require config_path
require_relative 'batch.rb'
require_relative 'outlining_text.rb'

# Then run the batch.rb
upload_images
response
download_vision_json
save_ordered_text_file
save_corrected_text_file

# and then run the outlining_text.rb
all_images
