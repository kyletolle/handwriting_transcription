# handwriting-transcription

```
# Information

## Before you begin
https://cloud.google.com/vision/docs/before-you-begin

## Gem library
https://cloud.google.com/vision/docs/quickstart-client-libraries

# Batch Processing

## Installing
```
rbenv shell 2.6.5
gem install google-cloud-storage
gem install google-cloud-vision
export GOOGLE_APPLICATION_CREDENTIAL='handwriting-transcription-2e1425be4478.json' # Is this really needed?
```

## Usage

Follow these steps to perform handwriting transcription on images and end up with a raw text file of the text content.

- Get your images named something like `page1.jpg
- Open the `lib/handwriting_transcription/batch.rb` file
- Modify the `folder_path` to point to the correct location
- Make sure `image_prefix` is correct
- Edit `image_numbers` to refer to the pages you're working with
- Make sure `image_suffix` is correct
- Make sure `bucket_name` is correct
- Start `irb`
- Run the following commands
```
require './lib/handwriting_transcription/batch'
upload_images
response
download_vision_json
save_raw_text
save_markdown_text
```

# Outlining Text

## Installing

To use the latest version of rmagick, you have to use imagemagick 6. Follow the steps at https://github.com/rmagick/rmagick/issues/256#issuecomment-273097027 to install.

```
brew install imagemagick@6
rbenv shell 2.6.5
LDFLAGS=-L/usr/local/opt/imagemagick@6/lib \
CPPFLAGS=-I/usr/local/opt/imagemagick@6/include \
PKG_CONFIG_PATH=/usr/local/opt/imagemagick@6/lib/pkgconfig \
gem install rmagick

```

## Usage

- Open the `lib/handwriting_transcription/outlining_text.rb` file
- Make sure `folder_path` points to the correct folder
- Start `irb`
- Run the following commands
```
require './lib/handwriting_transcription/outlining_text'
all_images
```

