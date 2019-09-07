# Needed to set up my account first: https://cloud.google.com/vision/docs/before-you-begin
# Following the example at https://cloud.google.com/vision/docs/handwriting#vision-document-text-detection-ruby
# And instead of setting the env var for the credentials, I downloaded the json
# file and reference it here.
# Here was a quick start with some info: https://cloud.google.com/vision/docs/quickstart-client-libraries
# Here's the ruby client repo: https://github.com/googleapis/google-cloud-ruby/blob/master/README.md
image_path = "page1.jpg"

require "google/cloud/vision"

image_annotator = Google::Cloud::Vision::ImageAnnotator.new(credentials: 'handwriting-transcription-2e1425be4478.json')

response = image_annotator.document_text_detection image: image_path

text = ""
response.responses.each do |res|
  # Docs for the response data: https://cloud.google.com/vision/docs/reference/rest/v1/AnnotateImageResponse#EntityAnnotation
  res.text_annotations.each do |annotation|
    text << annotation.description
  end
end

puts text
