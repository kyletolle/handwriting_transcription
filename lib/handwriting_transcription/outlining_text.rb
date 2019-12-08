require 'rmagick'
require 'json'

# For a single image

def single_image
  page_number = 1

  input_image_path = "/Users/kyle/Dropbox/code/kyletolle/handwriting_transcription/page#{page_number}.jpg"
  image = Magick::Image.read(input_image_path)[0]
  json_path ="/Users/kyle/Dropbox/code/kyletolle/handwriting_transcription/output-#{page_number}-to-#{page_number}.json"
  json_text = File.read(json_path)
  json = JSON.parse(json_text)

  bounding_box = json["responses"].first["textAnnotations"][1]["boundingPoly"]
  vertices = bounding_box["vertices"]

  draw = Magick::Draw.new

  # For drawing boxes around all words.
  # text_annotations = json["responses"].first["textAnnotations"][1..-1]
  # text_annotations.each do |text_annotation|
  #   bounding_box = text_annotation["boundingPoly"]
  #   vertices = bounding_box["vertices"]

  #   p1 = [ vertices[0]['x'], vertices[0]['y'] ]
  #   p2 = [ vertices[1]['x'], vertices[1]['y'] ]
  #   p3 = [ vertices[3]['x'], vertices[3]['y'] ]
  #   p4 = [ vertices[2]['x'], vertices[2]['y'] ]

  #   draw.line(p1[0],p1[1], p2[0], p2[1])
  #   draw.line(p1[0],p1[1], p3[0], p3[1])
  #   draw.line(p2[0],p2[1], p4[0], p4[1])
  #   draw.line(p3[0],p3[1], p4[0], p4[1])
  # end

  # For drawing colored boxes around all symbols

  confidence_symbols_to_colors = {
    very_confidence: '#BED1D8',
    moderately_confidence: '#FFAE03',
    sort_of_confidence: '#E67F0D',
    low_confidence: '#E9190F'
  }

  numbers_to_confidence_symbols = {
    80..100 => :very_confidence,
    50..80 => :moderately_confidence,
    31..50 => :sort_of_confidence,
    0..30 => :low_confidence
  }

  pages = json["responses"].first["fullTextAnnotation"]['pages']
  blocks = pages.map{|p| p['blocks'] }.flatten.compact
  paragraphs = blocks.map{|b| b['paragraphs'] }.flatten.compact
  words = paragraphs.map{|p| p['words'] }.flatten.compact
  symbols = words.map{|w| w['symbols'] }.flatten.compact
  symbol_total = symbols.count
  symbols.each.with_index do |symbol, index|
    puts "Processing symbol #{index} of #{symbol_count}"
    bounding_box = symbol["boundingBox"]
    vertices = bounding_box["vertices"]
    confidence_number = (symbol['confidence'] * 100).to_i
    confidence_symbol = numbers_to_confidence_symbols.select{|n| n === confidence_number }.values.first
    color = confidence_symbols_to_colors[confidence_symbol]

    draw.stroke(color)
    draw.stroke_width(5)

    p1 = [ vertices[0]['x'], vertices[0]['y'] ]
    p2 = [ vertices[1]['x'], vertices[1]['y'] ]
    p3 = [ vertices[3]['x'], vertices[3]['y'] ]
    p4 = [ vertices[2]['x'], vertices[2]['y'] ]

    draw.line(p1[0],p1[1], p2[0], p2[1])
    draw.line(p1[0],p1[1], p3[0], p3[1])
    draw.line(p2[0],p2[1], p4[0], p4[1])
    draw.line(p3[0],p3[1], p4[0], p4[1])

    draw.draw(image)
  end
  output_image_path = "/Users/kyle/Dropbox/code/kyletolle/handwriting_transcription/page#{page_number}.5px.symbols.jpg"
  image.write(output_image_path)
end

###

# def folder_path
#   # File.join('', 'Users', 'kyle', 'Dropbox', 'everything', 'novels', 'bones-of-a-broken-world', 'draft-1', 'handwriting-batch-3')
#   File.join('', 'Users', 'kyletolle', 'Dropbox', 'everything', 'iomeselia', 'iomesel-journal', 'handwriting-batch-2')
# end

# def image_prefix
#   # 'bones-of-a-broken-world-draft-1-page-'
#   'page'
# end
# def full_image_prefix
#   File.join(folder_path, image_prefix)
# end
# def image_suffix
#   # '-300dpi-bw.png'
#   '.jpg'
# end

def all_images
  # For all images:
  image_text_files = Dir
    .children(folder_path)
    .select do |path|
      path.start_with?('output-')
    end
    .sort
      # .tap{|fs| puts fs }
  image_text_data = image_text_files.map do |path|
    File.read(File.join(folder_path, path))
  end
  image_jsons = image_text_data.map do |json_string|
    JSON.parse(json_string)
  end
  page_regex = /#{image_prefix}(\d+)#{image_suffix}/
  ordered_image_jsons = image_jsons.sort do |a, b|
    a_uri = a['responses'].first['context']['uri']
    b_uri = b['responses'].first['context']['uri']
    a_num = a_uri.match(page_regex)[1].to_i
    b_num = b_uri.match(page_regex)[1].to_i
    a_num <=> b_num
  end

  ordered_images_count = ordered_image_jsons.count
  ordered_image_jsons.each.with_index do |ordered_image_json, image_index|
    # next unless image_index == 4

    puts "Processing image #{image_index+1} of #{ordered_images_count}"
    uri = ordered_image_json['responses'].first['context']['uri']
    # puts "Processing URI #{uri}"
    page_number = uri.match(page_regex)[1].to_i
    # puts "Processing page number #{page_number}"

    input_image_path = full_image_path(page_number)
    # puts "File.exist?(#{input_image_path}): #{File.exist?(input_image_path)}"
    image = Magick::Image.read(input_image_path)[0]
    # json_path ="/Users/kyle/Dropbox/code/kyletolle/handwriting_transcription/output-#{page_number}-to-#{page_number}.json"
    # json_text = File.read(json_path)
    # json = JSON.parse(json_text)

    bounding_box = ordered_image_json["responses"].first["textAnnotations"][1]["boundingPoly"]
    vertices = bounding_box["vertices"]

    confidence_symbols_to_colors = {
      # very_confidence: '#BED1D8',
      # very_confidence: '#000000',
      very_confidence: '#555',
      moderately_confidence: '#FFAE03',
      sort_of_confidence: '#E67F0D',
      low_confidence: '#E9190F'
    }

    numbers_to_confidence_symbols = {
      80..100 => :very_confidence,
      50..80 => :moderately_confidence,
      31..50 => :sort_of_confidence,
      0..30 => :low_confidence
    }

    numbers_to_stroke_opacity = {
      80..100 => '35%',
      60..80 => '100%',
      31..60 => '100%',
      0..30 => '100%'
    }
    numbers_to_stroke_width = {
      80..100 => 2,
      # 80..100 => 4,
      50..80 => 5,
      # 50..80 => 4,
      31..50 => 5,
      0..30 => 5
    }

    pages = ordered_image_json["responses"].first["fullTextAnnotation"]['pages']
    blocks = pages.map{|p| p['blocks'] }.flatten.compact
    paragraphs = blocks.map{|b| b['paragraphs'] }.flatten.compact
    words = paragraphs.map{|p| p['words'] }.flatten.compact
    symbols = words.map{|w| w['symbols'] }.flatten.compact
    symbols_total = symbols.count
    symbols.each.with_index do |symbol, symbol_index|
      # next unless symbol_index == 41

      # puts "    Processing symbol #{symbol_index+1} of #{symbols_total}"
      bounding_box = symbol["boundingBox"]
      vertices = bounding_box["vertices"]
      confidence = symbol['confidence'] || 0
      confidence_number = (confidence * 100).to_i
      confidence_symbol = numbers_to_confidence_symbols.select{|n| n === confidence_number }.values.first
      color = confidence_symbols_to_colors[confidence_symbol]
      stroke_opacity = numbers_to_stroke_opacity.select{|n| n === confidence_number }.values.first
      stroke_width = numbers_to_stroke_width.select{|n| n === confidence_number }.values.first

      draw = Magick::Draw.new
      draw.fill_opacity(0)
      draw.stroke(color)
      draw.stroke_opacity(stroke_opacity)
      # draw.stroke_opacity('100%')
      draw.stroke_width(stroke_width)

      p1x = vertices[0]['x'] || 0
      p1y = vertices[0]['y'] || 0
      # p2x = vertices[1]['x']
      # p2y = vertices[1]['y']
      # p3x = vertices[3]['x']
      # p3y = vertices[3]['y']
      p4x = vertices[2]['x'] || 0
      p4y = vertices[2]['y'] || 0

      unless p1x && p1y && p4x && p4y
      # unless p1x && p1y && p2x && p2y && p3x && p3y && p4x && p4y
        puts "Error: Missing at least one vertex for image json block from file #{image_text_files[image_index]} for page#{page_number}.jpg"
        puts "Error: Vertices:"
        puts vertices
        next
      end

      # puts "trying to draw rectangle at #{p1x}, #{p1y}, #{p3x}, #{p3y}"
      # draw.roundrectangle(p1x, p1y, p4x, p4y, 5, 5)
      draw.rectangle(p1x, p1y, p4x, p4y)
      # draw.line(p1x, p1y, p2x, p2y)
      # draw.line(p1x, p1y, p3x, p3y)
      # draw.line(p2x, p2y, p4x, p4y)
      # draw.line(p3x, p3y, p4x, p4y)

      draw.draw(image)
      next
    end
    # After exploring this, I'm confident that missing vertices should be
    # treated as 0s
    altered_image_suffix = image_suffix
      .split('.')
      .insert(1, 'symbol_confidence')
      .join('.')
    output_image_path = "#{full_image_prefix}#{page_number}#{altered_image_suffix}"
    # output_image_path = "/Users/kyle/Dropbox/code/kyletolle/handwriting_transcription/page#{page_number}.symbol_confidence.missingvertices.jpg"
    image.write(output_image_path)
  end
  puts "Finished drawing on images..."
end
