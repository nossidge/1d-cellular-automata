#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# Convert an alphanumeric input to a png image file, using characters as pixels.
# Colour will be the same ratio, but brightness will depend on the character.
# Can be used from console, or as a Ruby library.
################################################################################

# Chunky and Oily do the exact same thing, but Oily is faster.
# Chunky is pure Ruby, Oily has some faster methods written in C.
begin
  require 'oily_png'
rescue LoadError
  require 'chunky_png'
end

require_relative 'looped_array.rb'

################################################################################

class PicFromNumbers
	CHARS = ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
	         'abcdefghijklmnopqrstuvwxyz').split('')
	
	attr_accessor :base_num
	attr_accessor :colour_invert
	attr_accessor :image_file
	attr_accessor :colour_r
	attr_accessor :colour_g
	attr_accessor :colour_b
	
	attr_reader :input_text_array
	attr_reader :pixel_size
	attr_reader :metadata
	
  def initialize(input_text_array)
		@colour_invert = false
		@image_file = "pic_#{Time.now.to_i.to_s}.png"
		set_colour(255,255,255)
		
		@pixel_size = 1
		change_text(input_text_array)
  end
	
	def change_text(input_text_array)
		@input_text_array = input_text_array
		set_dimensions()
		@input_text_array
	end
	
	def pixel_size=(input_size)
		@pixel_size = input_size
		set_dimensions()
		@pixel_size
	end
	
	# This uses the LoopedArray class to cycle through colours.
	# So convert to array if not already.
	# Also, mod by 256 so we are sure the number is in colour range.
	def set_colour(r,g,b)
		@colour_r = LoopedArray.new [*r].map {|i| i % 256}
		@colour_g = LoopedArray.new [*g].map {|i| i % 256}
		@colour_b = LoopedArray.new [*b].map {|i| i % 256}
	end
	
	def set_dimensions
		# Find the highest number in the lines and the longest len.
		@highest_num = 0
		highest_len = 0
		@input_text_array.each do |i|
			i_split = i.split('')
			num = i_split.sort.uniq.map{ |j| CHARS.index(j) }.sort[-1]
			len = i_split.length
			
			@highest_num = num if num > @highest_num
			highest_len = len if len > highest_len
		end
		
		# The highest number character in the array.
		@highest_num = @base_num if @base_num

		# Get the dimensions of the image.
		@x_length = @pixel_size * highest_len
		@y_length = @pixel_size * @input_text_array.length
	end
	
	# Set one or more metadata key/value pairs.
	# Allow Hash or nil only.
	def metadata=(metadata_hash)
		if metadata_hash.nil? or metadata_hash.is_a? Hash
			@metadata = metadata_hash
		else
			raise TypeError, 'A hash is required'
		end
	end
	
	# Create the image to file.
	def generate_image
		set_dimensions()
		
		# Create an image from scratch, save as an interlaced PNG.
		png = ChunkyPNG::Image.new(@x_length, @y_length, ChunkyPNG::Color::TRANSPARENT)

		# Loop along the string array and write each char as a square.
		i_line = 0
		@input_text_array.each do |line|

			# Get the colour for the line.
			line_colour_r = @colour_r.next
			line_colour_g = @colour_g.next
			line_colour_b = @colour_b.next

			# Loop through each character, and alter the base line colour according
			#   to the value of the cell.
			i_char = 0
			line.split('').each do |char|
				
				# The colour multiplier of the cell.
				multiplier = CHARS.index(char).to_f / @highest_num
				
				# Wrap in a method using a begin/rescue block.
				# Fixes weird bug that I can't seem to replicate.
				def try_colour(multiplier, line_colour)
					begin
						(multiplier * line_colour).to_i
					rescue
						255
					end
				end
				colour_r = try_colour(multiplier,line_colour_r)
				colour_g = try_colour(multiplier,line_colour_g)
				colour_b = try_colour(multiplier,line_colour_b)
				
				# Handle inversion of colours if necessary.
				if @colour_invert
					colour_r = 255 - colour_r
					colour_g = 255 - colour_g
					colour_b = 255 - colour_b
				end
				colour = ChunkyPNG::Color.rgba(colour_r, colour_g, colour_b, 255)
				
				# Draw each square.
				png.rect(i_char, i_line,
					i_char+@pixel_size-1, i_line+@pixel_size-1,
					colour, colour
				)

				i_char += @pixel_size
			end
			i_line += @pixel_size
		end
		
		# Add metadata if necessary.
		if @metadata
			@metadata.each do |key, value|
				png.metadata[key.to_s] = value.to_s
			end
		end

		# Save to disk.
		png.save(@image_file, :interlace => true)
	end
end

################################################################################

# Don't need to do any console stuff if it's being included as a library.
if __FILE__ == $0

	##############################################################################

	require 'optparse'
	require_relative 'common.rb'
	
	options = {}
	options[:pixel_size]    = 1
	options[:base_num]      = nil
	options[:colour_invert] = false
	options[:image_file]    = "pic_#{Time.now.to_i.to_s}.png"

	options[:colour_r] = [255]
	options[:colour_g] = [255]
	options[:colour_b] = [255]
	
	options[:metadata] = nil

	# Get all of the command-line options.
	optparse = OptionParser.new do |opts|
		
		# Set a banner, displayed at the top of the help screen.
		opts.banner = "Usage:  automata.rb -s'0123456789' | num_to_pic.rb [options]"

		# Easy to deal with options.
		opts.on('-p', '--pixel     NUMBER', Integer, 'Size of pixels (zoom)') do |n|
			options[:pixel_size] = n if 0 < n
		end
		opts.on('-b', '--base      NUMBER', Integer, 'Base number') do |n|
			options[:base_num] = n if 0 < n
		end
		opts.on('-i', '--invert', 'Invert the image colours') do |b|
			options[:colour_invert] = b
		end
		opts.on('-f', '--file      STRING', 'File name for the resulting .png') do |s|
			options[:image_file] = s
		end
		
		# Colours. Make sure the arguments are integers >= 0 and < 256.
		opts.on('-R', '--red       NUM[,NUM]', Array, 'Red component of image') do |list|
			options[:colour_r] =
				each_to_int(list, OptionParser::ParseError).map { |i| i = i.abs % 256 }
		end
		opts.on('-G', '--green     NUM[,NUM]', Array, 'Green component of image') do |list|
			options[:colour_g] =
				each_to_int(list, OptionParser::ParseError).map { |i| i = i.abs % 256 }
		end
		opts.on('-B', '--blue      NUM[,NUM]', Array, 'Blue component of image') do |list|
			options[:colour_b] =
				each_to_int(list, OptionParser::ParseError).map { |i| i = i.abs % 256 }
		end
		
		# Metadata for the png. This needs to be a string in the form "key1:val1;key2:val2".
		# This will be transformed into a hash.
		opts.on('-m', '--metadata  STRING', 'Hash of metadata for the .png') do |s|
			begin
				options[:metadata] = s.to_h
			rescue
				raise OptionParser::ParseError, 'Argument must be in the form "key1:val1;key2:val2"'
			end
		end
		
		# Help output.
		opts.on('-h', '--help', 'Display this help screen' ) do
			puts opts
			exit
		end
	end
	
	# Parse the options and show errors on failure.
	begin
		optparse.parse!(ARGV)
	rescue OptionParser::ParseError => e
		puts e
		exit 1
	end

  ##############################################################################

	# Get piped info.
	lines = []
	lines << '01000000A0000000000a0'
	lines << '010X00000A000000000B0'
	lines << '0100000000A00000000a0'
	lines << '01000000000A0000X00a0'
	lines << '0X0000000000A000000a0'
	lines = []
	ARGF.each do |line|
		lines << line.strip
	end

	# Create pic from inputs.
	pic = PicFromNumbers.new(lines)
	pic.base_num      = options[:base_num]
	pic.colour_invert = options[:colour_invert]
	pic.image_file    = options[:image_file]
	pic.pixel_size    = options[:pixel_size]
	pic.set_colour(options[:colour_r],options[:colour_g],options[:colour_b])
	pic.metadata      = options[:metadata]
	pic.generate_image

  ##############################################################################
	
end

################################################################################
