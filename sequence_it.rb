#! /usr/bin/env ruby
require 'net/http'
require 'uri'
require 'open-uri'
require 'pry'
require 'json'

# creates sequence diagram
class SequenceIt
  attr_accessor :sequence_file, :png_file, :destination_path

  def initialize(arg)
    raise ArgumentError 'not a .sequence file' unless arg.ends_with?('.sequence')
    @sequence_file = "#{arg}"
    @png_file = "#{sequence_file.gsub('.sequence', '.png')}"
    @destination_path = "#{Dir.pwd}/"
  end

  def create_diagram
    raise AgrmumentError unless File.exist?(sequence_file)

    $stderr.puts "Uploading: #{sequence_file}"
    image_url = convert_via_api

    $stderr.puts "Getting diagram from: #{image_url}"
    retrieve_diagram(image_url)

    $stderr.puts "Opening: #{png_file}"
    open_image
  end

  private

  def convert_via_api
    response = Net::HTTP.post_form(uri, params)
    return unless response.is_a?(Net::HTTPSuccess)
    file_location = response.body.split('"')[1]
    "http://www.websequencediagrams.com/#{file_location}"
  end

  def retrieve_diagram(image_url)
    File.open(destination_path + png_file, 'w+') do |f|
      f << open(image_url).read
    end
  end

  def open_image
    case RUBY_PLATFORM
    when /linux/i
      system("gnome-open file://#{destination_path + png_file}")
    else
      system("open #{destination_path + png_file}")
    end
  end

  protected

  def uri
    URI.parse('http://www.websequencediagrams.com/index.php')
  end

  def params
    text = File.read(sequence_file)
    { 'style' => 'modern-blue', 'message' => text }
  end
end

# run
if ARGV[0] && $stdout.tty?
  diagram = SequenceIt.new(ARGV[0])
  diagram.create_diagram
else
  $stderr.puts('Missing argument')
end

