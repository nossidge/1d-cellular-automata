#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# Read metadata tag of automata png files.
# Example usage:
#   ruby png_metadata.rb pic_1445729333.png
################################################################################

begin
  require 'oily_png'
rescue LoadError
  require 'chunky_png'
end

begin
	image = ChunkyPNG::Image.from_file ARGV[0]
	puts image.metadata['automata']
rescue
	puts "Invalid file: #{ARGV[0]}"
end

################################################################################
