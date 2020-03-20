#! /usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'open-uri'
require 'pry'
require 'json'

# SequenceIt: Creates sequence diagram by uploading a sequence file to the
# websequencediagram.com API. The resulting PNG file is saved alongside the
# originating markdown with the same name.
class SequenceIt
  class ConversionFailed < StandardError; end
  class NotFound < StandardError # rubocop:disable Style/Documentation
    def initialize(path)
      super("file not found: #{path}")
    end
  end
  class InvalidType < StandardError # rubocop:disable Style/Documentation
    def initialize
      super("accepted filetypes: #{EXTENSIONS}")
    end
  end

  EXTENSIONS = [
    SEQ      = '.seq',
    SEQUENCE = '.sequence'
  ].freeze
  HOST       = 'https://www.websequencediagrams.com'
  STYLE      = 'earth'
  ROOT       = Pathname.new(Dir.pwd)
  EXT_REGEX  = /^.*(#{EXTENSIONS.join('|')})\z/.freeze

  def self.build(file_path)
    new(file_path).build
  rescue StandardError => e
    warn e.message
  end

  def initialize(file_path)
    raise InvalidType unless file_path.match(EXT_REGEX)
    raise NotFound, file_path unless File.exist?(file_path)

    @sequence_file = Pathname.new(ROOT + file_path)
  end

  def build
    img = transform(sequence_file)

    file = download(img)
    open_image(file.path)
  end

  private

  attr_reader :sequence_file

  # @param file_path [String] The location of the sequence file
  # @return [String] the image location query param (eg. ?img=msc051812355)
  def transform(file_path)
    warn "Uploading: #{file_path}"

    params = { 'style' => STYLE, 'message' => File.read(file_path) }
    uri    = URI.parse(HOST)

    response = Net::HTTP.post_form(uri, params)
    raise ConversionFailed, response.body unless response.is_a?(Net::HTTPSuccess)

    # NOTE: The response body is a ruby hash formated string not JSON :(
    YAML.safe_load(response.body)['img']
  end

  # @param url [String] The img query param
  # @param png [String] The destinaion file path for the downloaded png image
  def download(img)
    uri = URI.parse(HOST + img)
    warn "Downloading diagram from: #{uri}"

    png = sequence_file.sub('.sequence', '.png')
    File.open(png, 'w+') do |f|
      # uses open-uri not the standard library so ignoring security warning
      f << open(uri).read # rubocop:disable Security/Open
    end
  end

  # #param png_file [String] the png file path relative to current working dir
  def open_image(png_file)
    warn "Opening: #{png_file}"
    case RUBY_PLATFORM
    when /linux/i  then system("gnome-open file://#{png_file}")
    when /darwin/i then system("open #{png_file}")
    else raise StandardError "I don't know how to open the png on this OS"
    end
  end
end

# run
if ARGV[0] && $stdout.tty?
  SequenceIt.build(ARGV[0])
else
  warn('Missing argument')
end
