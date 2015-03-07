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

################################################################################

class PicFromNumbers
	CHARS = ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
	         'abcdefghijklmnopqrstuvwxyz').split('')
	
	attr_accessor :baseNum
	attr_accessor :colourInvert
	attr_accessor :imageFile
	attr_accessor :colourR
	attr_accessor :colourG
	attr_accessor :colourB
	
	attr_reader :inputTextArray
	attr_reader :pixelSize
	
  def initialize(inputTextArray)
		@colourInvert = false
		@imageFile = "pic_#{Time.now.to_i.to_s}.png"
		set_colour(255,255,255)
		
		@pixelSize = 1
		change_text(inputTextArray)
  end
	
	def change_text(inputTextArray)
		@inputTextArray = inputTextArray
		set_dimensions()
	end
	
	def change_pixel_size(pixelSize)
		@pixelSize = pixelSize
		set_dimensions()
	end
	
	def set_colour(r,g,b)
		@colourR = r % 256
		@colourG = g % 256
		@colourB = b % 256
	end
	
	def set_dimensions()
		# Find the highest number in the lines and the longest len.
		@highestNum = 0
		highestLen = 0
		@inputTextArray.each do |i|
			iSplit = i.split('')
			num = iSplit.sort.uniq.map{ |j| CHARS.index(j) }.sort[-1]
			len = iSplit.length
			
			@highestNum = num if num > @highestNum
			highestLen = len if len > highestLen
		end
		
		# The highest number character in the array.
		@highestNum = @baseNum if @baseNum

		# Get the dimensions of the image.
		@xLength = @pixelSize * highestLen
		@yLength = @pixelSize * @inputTextArray.length
	end
	
	def generate_image()
		set_dimensions()
		
		# Create an image from scratch, save as an interlaced PNG.
		png = ChunkyPNG::Image.new(@xLength, @yLength, ChunkyPNG::Color::TRANSPARENT)

		# Loop along the string array and write each char as a square.
		iLine = 0
		@inputTextArray.each do |line|
			iChar = 0
			line.split('').each do |char|
				
				# Colours.
				multiplier = CHARS.index(char).to_f / @highestNum
				colourR = (multiplier * @colourR).to_i
				colourG = (multiplier * @colourG).to_i
				colourB = (multiplier * @colourB).to_i
				colour = ChunkyPNG::Color.rgba(colourR, colourG, colourB, 255)
				
				# Draw each square.
				png.rect(iChar, iLine, 
					iChar+@pixelSize-1, iLine+@pixelSize-1, 
					colour, colour
				)

				iChar += @pixelSize
			end
			iLine += @pixelSize
		end

		# Save to disk.
		png.save(@imageFile, :interlace => true)
	end
end

################################################################################

# Don't need to do any console stuff if it's being included as a library.
if __FILE__ == $0

################################################################################

	require 'optparse'

	options = {}
	options[:pixelSize] = 1
	options[:baseNum] = nil
	options[:colourInvert] = false
	options[:imageFile] = "pic_#{Time.now.to_i.to_s}.png"

	options[:colourR] = 255
	options[:colourG] = 255
	options[:colourB] = 255

	# Get all of the command-line options.
	optparse = OptionParser.new do |opts|
		
		# Set a banner, displayed at the top of the help screen.
		opts.banner = "Usage:  automata.rb -s'0123456789' | num_to_pic.rb [options]"

		opts.on('-p', '--pixel NUMBER', Integer, 'Size of pixels (zoom)') do |n|
			options[:pixelSize] = n if 0 < n
		end
		opts.on('-b', '--base NUMBER', Integer, 'Base number') do |n|
			options[:baseNum] = n if 0 < n
		end
		opts.on('-i', '--invert', 'Invert the image colours') do |b|
			options[:colourInvert] = b
		end
		opts.on('-f', '--file STRING', 'imageFile') do |s|
			options[:imageFile] = s
		end
		
		# Colours
		opts.on('-R', '--red NUMBER', Integer, 'Red component') do |n|
			options[:colourR] = n if 0 <= n and n <= 255
		end
		opts.on('-G', '--green NUMBER', Integer, 'Green component') do |n|
			options[:colourG] = n if 0 <= n and n <= 255
		end
		opts.on('-B', '--blue NUMBER', Integer, 'Blue component') do |n|
			options[:colourB] = n if 0 <= n and n <= 255
		end
		
		opts.on('-h', '--help', 'Display this help screen' ) do
			puts opts
			exit
		end
	end
	optparse.parse!

################################################################################

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
	pic.baseNum      = options[:baseNum]
	pic.colourInvert = options[:colourInvert]
	pic.imageFile    = 'pics/' + options[:imageFile]
	pic.change_pixel_size(options[:pixelSize])
	pic.set_colour(options[:colourR],options[:colourG],options[:colourB])
	pic.generate_image

################################################################################
	
end

################################################################################
