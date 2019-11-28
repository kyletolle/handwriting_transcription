# Needed to set up my account first: https://cloud.google.com/vision/docs/before-you-begin
# Following the example at https://cloud.google.com/vision/docs/handwriting#vision-document-text-detection-ruby
# And instead of setting the env var for the credentials, I downloaded the json
# file and reference it here.
# Here was a quick start with some info: https://cloud.google.com/vision/docs/quickstart-client-libraries
# Here's the ruby client repo: https://github.com/googleapis/google-cloud-ruby/blob/master/README.md

# TODO: I'm trying to see if I can get online small batch processing working for
# jpg or not... https://cloud.google.com/vision/docs/file-small-batch Okay,
# doesn't look like that'll work because it doesn't support passing in multiple
# files. We probably need to try offline large batch processing...

iomesel_journal_batch_1_config = {
  folder_path: File.join('', 'Users', 'kyletolle', 'Dropbox', 'everything', 'iomeselia', 'iomesel-journal', 'handwriting-batch-1'),
  image_prefix: 'page',
  image_numbers: ((1..157).to_a - [63, 64]),
  image_suffix: '.jpg',
  google_project_id: 'handr-247100',
  bucket_name: 'iomesel-journal-batch-1',
  bucket_location: 'us-west2',
  bucket_storage_class: 'standard',
  google_credentials_path: 'handwriting-transcription-2e1425be4478.json',
}

iomesel_journal_batch_2_config = {
  folder_path: File.join('', 'Users', 'kyletolle', 'Dropbox', 'everything', 'iomeselia', 'iomesel-journal', 'handwriting-batch-2'),
  image_prefix: 'page',
  image_numbers: (158..178).to_a,
  image_suffix: '.jpg',
  google_project_id: 'handr-247100',
  bucket_name: 'iomesel-journal-batch-2',
  bucket_location: 'us-west2',
  bucket_storage_class: 'standard',
  google_credentials_path: 'handwriting-transcription-2e1425be4478.json',
}

boabw_draft_1_config = {
  folder_path: File.join('', 'Users', 'kyletolle', 'Dropbox', 'everything', 'novels', 'bones-of-a-broken-world', 'draft-1', 'handwriting-batch-4'),
  image_prefix: 'bones-of-a-broken-world-draft-1-page-',
  image_numbers: @image_numbers ||= (14..15).to_a,
  image_suffix: '-300dpi-bw.png',
  google_project_id: 'handr-247100',
  bucket_name: 'bones-of-a-broken-world-draft-1-batch-4',
  bucket_location: 'us-west2',
  bucket_storage_class: 'standard',
  google_credentials_path: 'handwriting-transcription-2e1425be4478.json',
}


def batch_config
  iomesel_journal_config
end

def folder_path
  # File.join('', 'Users', 'kyletolle', 'Dropbox', 'everything', 'novels', 'bones-of-a-broken-world', 'draft-1', 'handwriting-batch-4')
  # File.join('', 'Users', 'kyletolle', 'Dropbox', 'everything', 'iomeselia', 'iomesel-journal', 'handwriting-batch-2')
  batch_config[:folder_path]
end

def image_prefix
  # 'page'
  # 'bones-of-a-broken-world-draft-1-page-'
  batch_config[:image_prefix]
end
def full_image_prefix
  File.join(folder_path, image_prefix)
end

def image_numbers
  # @image_numbers ||= ((1..157).to_a - [63, 64])
  # @image_numbers ||= (14..15).to_a
  # @image_numbers ||= (158..178).to_a
  batch_config[:image_numbers]
end
def image_suffix
  # '.jpg'
  # '-300dpi-bw.png'
  batch_config[:image_suffix]
end
def full_image_path(number)
  "#{full_image_prefix}#{number}#{image_suffix}"
end
def image_paths
  image_numbers.map do |image_number|
    full_image_path(image_number)
  end
end

require "google/cloud/storage"
require "google/cloud/vision"
require 'json'

def google_project_id
  batch_config[:google_project_id]
end
def bucket_name
  # 'iomesel-journal-batch-2'
  # 'bones-of-a-broken-world-draft-1-batch-4'
  batch_config[:bucket_name]
end
def location
  # 'us-west2'
  batch_config[:bucket_location]
end
def storage_class
  # 'standard'
  batch_config[:bucket_storage_class]
end

# Code at https://github.com/googleapis/google-cloud-ruby/tree/master/google-cloud-storage
# Samples at https://github.com/GoogleCloudPlatform/ruby-docs-samples/blob/master/storage/files.rb
def storage
  @storage ||= Google::Cloud::Storage.new(
    project_id: google_project_id,
    credentials: batch_config[:google_credentials_path]
  )
end

# Create bucket if it doesn't exist
def existing_bucket
  @existing_bucket ||= storage.buckets.select { |b| b.name == bucket_name }.first
end
def new_bucket
  # Following docs at https://cloud.google.com/storage/docs/creating-buckets#storage-create-bucket-code_samples
  @new_bucket ||= storage.create_bucket(
    bucket_name,
    location:      location,
    storage_class: storage_class
  )
  .tap do |b|
    puts "Created bucket #{b.name} in #{location} with #{storage_class} class"
  end
end

def bucket
  @bucket ||= (existing_bucket || new_bucket)
end

def existing_files
  @existing_files ||= bucket.files prefix: image_prefix
end

# Upload files unless they already exist
def upload_images
  puts "Starting image upload..."
  start_time = Time.now.to_i
  image_paths.each do |image_path|
    puts "Attempting to upload `#{image_path}`"
    image_base_name = File.basename(image_path)
    image_already_uploaded = existing_files
      .find {|f| f.name == image_base_name }

    if image_already_uploaded
      puts "Image `#{image_base_name}` already uploaded, skipping."
      next
    end

    bucket.create_file(image_path, image_base_name)
      .tap{|ip| puts "Uploaded file from `#{image_path}` to `#{image_base_name}` in bucket `#{bucket_name}`" }
  end
  .tap do
    end_time = Time.now.to_i
    time_diff = end_time - start_time
    puts "Took `#{time_diff}` seconds to upload images"
  end
end

def files_to_work_with
  image_prefix_basename = File.basename(full_image_prefix)
  @files_to_work_with ||= bucket.files prefix: image_prefix_basename
end

# Following batch examples at: https://cloud.google.com/vision/docs/batch
# Ruby API docs: https://googleapis.github.io/google-cloud-ruby/docs/google-cloud-vision/latest/Google/Cloud/Vision

def image_names
  @image_names ||= files_to_work_with.map(&:name)
end
def input_image_uris
  @input_image_uris ||= image_names.map{|name| "gs://#{bucket_name}/#{name}" }
end
def output_uri
  # Note: Needed the '/' at the end of the bucket name.
  @output_uri ||= "gs://#{bucket_name}/"
end

# TODO: We also only want to re-process images that haven't been processed
# already.
def requests
  @requests ||= input_image_uris.map do |input_image_uri|
    type = :DOCUMENT_TEXT_DETECTION
    feature = { type: type }
    features = [ feature ]

    source = { image_uri: input_image_uri }
    image = { source: source }

    _request = {
      image: image,
      features: features
    }
  end
end

def gcs_destination
  @gcs_destination ||= {
    uri: output_uri
  }
end

# The max number of responses to output in each JSON file
def batch_size
  1
end
def output_config
  @output_config ||= {
    gcs_destination: gcs_destination,
    batch_size: batch_size
  }
end


def image_annotator_client
  @image_annotator_client ||= Google::Cloud::Vision::ImageAnnotator.new(
    version: :v1,
    credentials: batch_config[:google_credentials_path]
  )
end

# Make the long-running operation request
def operation
  @operation ||= image_annotator_client.async_batch_annotate_images(
    requests,
    output_config
  )
end

def response
  @response ||=
    begin
      puts "Starting batch text detection..."
      start_time = Time.now.to_i
      operation.wait_until_done!

      raise operation.results.message if operation.error?

      end_time = Time.now.to_i
      time_diff = end_time - start_time
      puts "Took `#{time_diff}` seconds to process images"
      operation.response
    end
end

# Download the files

def gcs_output_uri
  # The output is written to GCS with the provided output_uri as prefix
  # Note: This seems to be exactly the same as the output_uri
  @gcs_output_uri ||=
    response
    .output_config
    .gcs_destination
    .uri
    .tap {|uri| puts "Output written to GCS with prefix: #{uri}" }
end

OUTPUT_FILE_PREFIX = 'output-'

def image_output_files
  bucket.files prefix: OUTPUT_FILE_PREFIX
end

def download_vision_json
  puts "Starting download of json responses"
  start_time = Time.now.to_i

  image_output_files.each do |image_output_file|
    local_path = File.join(folder_path, image_output_file.name)
    puts "Wanting to download json file to `#{local_path}`"
    image_output_file.download local_path
  end
  .tap do
    end_time = Time.now.to_i
    time_diff = end_time - start_time
    puts "Took `#{time_diff}` seconds to download json responses"
  end
end


def image_text_files
  Dir
    .children(folder_path)
    .select do |path|
      path.start_with?(OUTPUT_FILE_PREFIX)
    end
      .sort
end

def image_text_data
  @image_text_data ||= image_text_files.map do |path|
    File.read(File.join(folder_path, path))
  end
end

def image_jsons
  @image_jsons ||= image_text_data.map do |json_string|
    JSON.parse(json_string)
  end
end

def ordered_image_jsons
  @ordered_image_jsons ||= image_jsons.sort do |a, b|
    a_uri = a['responses'].first['context']['uri']
    b_uri = b['responses'].first['context']['uri']
    page_regex = /#{image_prefix}(\d+)#{image_suffix}/
    a_num = a_uri.match(page_regex)[1].to_i
    b_num = b_uri.match(page_regex)[1].to_i
    a_num <=> b_num
  end
end

# def inspect_ordering
#   ordered_uris = ordered_image_jsons.map do |oij|
#     oij['responses'].first['context']['uri']
#   end
#   pp ordered_uris
# end

def full_image_text(image_json)
  puts "Processing: `#{image_json['responses'].first['context']['uri']}`"
  image_json['responses']
    .first['textAnnotations']
    .first['description']
end

def full_image_texts
  @full_image_texts ||= ordered_image_jsons
    .map do |ordered_image_json|
      full_image_text(ordered_image_json)
    end
end

def combined_image_text_raw
  all_text = ""
  full_image_texts.each.with_index do |full_image_text, index|
    all_text += full_image_text+"\n"
  end

  all_text
end

def combined_image_text_markdown
  all_text = ""
  full_image_texts.each.with_index do |full_image_text, index|
    page_number = image_numbers[index]
    all_text += <<PAGE
# Page #{page_number}

#{full_image_text}
PAGE
  end
  all_text
end

ORDERED_MARKDOWN_FILE_NAME = 'handwriting-transcribed-text.ordered.md'
def markdown_file_path
  File.join(folder_path, ORDERED_MARKDOWN_FILE_NAME)
end

def save_markdown_text
  File.open(markdown_file_path, 'w') do |f|
    f.write(combined_image_text_markdown)
  end
end

ORDERED_TEXT_FILE_NAME = 'handwriting-transcribed-text.ordered.txt'
def raw_file_path
  File.join(folder_path, ORDERED_TEXT_FILE_NAME)
end

def save_raw_text
  File.open(raw_file_path, 'w') do |f|
    puts "Trying to open file at `#{f}`"
    f.write(combined_image_text_raw)
  end
end

###

# See the README for steps to run
