#! /usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'open-uri'
require 'pry'
require 'json'
require 'optparse'

class NotFound < StandardError # rubocop:disable Style/Documentation
  def initialize(path)
    super("file not found: #{path}")
  end
end

class InvalidType < StandardError # rubocop:disable Style/Documentation
  def initialize(extensions)
    super("accepted filetypes: #{extensions}")
  end
end

# Arguments: Handles parsing CLI arguments
class Arguments
  ROOT       = Pathname.new(Dir.pwd)
  EXTENSIONS = %w[.seq .sequence].freeze
  EXT_REGEX  = /^.*(#{EXTENSIONS.join('|')})\z/.freeze

  attr_accessor :file, :opts

  def self.parse(argv)
    new(argv).send(:parse)
  end

  def initialize(argv)
    @argv = argv
    @opts = {
      verbose: false,
      open: true
    }
  end

  private

  attr_reader :argv

  def parse
    option_parser.parse!(argv.dup)
    require_file
    self
  end

  def require_file
    f = argv.pop
    raise InvalidType, EXTENSIONS unless f.match(EXT_REGEX)

    self.file = Pathname.new(ROOT + f)
    raise NotFound, file unless File.exist?(file)
  end

  def option_parser
    OptionParser.new do |parser|
      banner(parser)
      help_arg(parser)
      open_arg(parser)
      verbose_arg(parser)
    end
  end

  def banner(parser)
    parser.banner = 'Usage: seq FILE [OPTIONS]'
  end

  def help_arg(parser)
    parser.on('-h', '--help', 'prints this help') do
      puts parser
      exit
    end
  end

  def open_arg(parser)
    parser.on('-o', '--open', 'open the file [DEFAULT: true]') do |o|
      opts[:open] = o
    end
  end

  def verbose_arg(parser)
    parser.on('-v', '--verbose', 'prints all actions') do |v|
      opts[:verbose] = v
    end
  end
end

# SequenceIt: Creates sequence diagram by uploading a sequence file to the
# websequencediagram.com API. The resulting PNG file is saved alongside the
# originating markdown with the same name.
class SequenceIt
  class ApiFailure < StandardError; end

  HOST  = 'https://www.websequencediagrams.com'
  STYLE = 'earth'

  def self.build(args)
    new(args).build
  end

  def initialize(arguments)
    @sequence_file = arguments.file
    @opts = arguments.opts
  end

  def build
    img = transform(File.read(@sequence_file))
    file = download(img, @sequence_file.sub(/\.seq.*\z/, '.png'))
    open_image(file.path)
  end

  private

  attr_reader :opts

  # @param message [String] The location of the sequence file
  # @return [String] the image location query param (eg. ?img=msc051812355)
  def transform(message)
    log 'uploading file to API'

    params = { 'style' => STYLE, 'message' => message }
    uri    = URI.parse(HOST)

    response = Net::HTTP.post_form(uri, params)
    raise ApiFailure, response.body unless response.is_a?(Net::HTTPSuccess)

    # NOTE: The response body is a ruby hash formated string not JSON :(
    YAML.safe_load(response.body)['img']
  end

  # @param img [String] the image location query param (eg. ?img=msc051812355)
  # @param filename [String] the name of the file
  # @return [File] The resulting file
  def download(img, filename)
    uri = URI.parse(HOST + img)
    log "downloading diagram from: #{uri}"

    File.open(filename, 'w+') do |f|
      # uses open-uri not the standard library so ignoring security warning
      f << open(uri).read # rubocop:disable Security/Open
    end
  end

  # @param png_file [String] the png file path relative to current working dir
  # @return [Nil]
  def open_image(png_file)
    return unless opts[:open]

    log "opening: #{png_file}"
    case RUBY_PLATFORM
    when /linux/i  then system("gnome-open file://#{png_file}")
    when /darwin/i then system("open #{png_file}")
    else raise StandardError "I don't know how to open the png on this OS"
    end
  end

  def log(message)
    warn(message) if opts[:verbose]
  end
end

# run
if $stdout.tty?
  begin
    SequenceIt.build(Arguments.parse(ARGV))
  rescue StandardError => e
    warn e.message
    exit
  end
end
