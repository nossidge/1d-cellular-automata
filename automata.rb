#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# One dimensional cellular automaton.
# http://mathworld.wolfram.com/ElementaryCellularAutomaton.html
################################################################################

require 'optparse'
require 'json'

require_relative 'common.rb'
require_relative 'cells.rb'

################################################################################

# Rotate a 2d array by 90 degrees.
class Array
	def rotate_right
		transpose.map &:reverse
	end
end

################################################################################

# Return a random string, using characters from an array.
def random_string(char_array, length,
		mirrored=false,
		centred=false, full_length=80, buffer_char='0')

	# Not mirrored. Just use pick at random for each character.
	if not mirrored
		buffer = length.times.map{char_array.sample.to_s}.join('')

	# Return a random mirrored string, like a palindrome.
	else
		# If the length is odd, start with one initial character.
		buffer = (length % 2 != 0) ? char_array.sample.to_s : ''

		# Start in the middle of the string, and iterate to the edges.
		(length / 2).times do
			rand_char = char_array.sample.to_s
			buffer = rand_char + buffer + rand_char
		end
	end

	# Write to the centre of the string, if necessary.
	# Pad the random portion between chars of '0' by default.
	buffer = buffer.center(full_length,buffer_char) if centred

	buffer
end

################################################################################

options = {}

# Just to make sure it works on my Windows env.
begin
	options[:cell_count] = `tput cols`.to_i - 1
rescue
	options[:cell_count] = 187
	options[:cell_count] = 166
	options[:cell_count] = 159
	options[:cell_count] = 119
end

options[:output_line_count] = options[:cell_count] / 2
options[:output_line_begin] = 1
options[:output_loop_forever] = false

options[:line_multiply] = 1
options[:line_multiply_delim] = ''

options[:rule_number] = nil
options[:rule_cool]   = false

options[:state_value]   = '1000001'
options[:state_value]   = nil
options[:state_random]  = false
options[:state_centred] = false
options[:state_random_mirrored] = false

options[:state_count] = 2
STATE_SYMBOLS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
options[:state_symbols] = ' o0Oo0Oo0O'
options[:state_symbols] = ' o()[]{}<>\/'
options[:state_symbols] = STATE_SYMBOLS
options[:state_random_prob] = nil

options[:wrap] = false
options[:initial_state_length] = nil

# This is for num_to_pic.rb
options[:image] = false
options[:colour_r] = 255
options[:colour_g] = 255
options[:colour_b] = 255
options[:image_file] = nil
options[:pixel_size] = 1
options[:metadata] = nil

# List of transformations to apply to the automaton output.
options[:transformation_queue] = []

################################################################################

# Nice default options.
# Need to make this a bit better.
defaultNames = [
	'mountain','mountains',
	'hanoi','hanoi1','hanoi2',
	'bubble','bubbles',
	'emboss','embossed',
	'giza','giza1','giza2',
	'scalpel'
]

# Reader-friendly list
default_names_to_output = [
	'mountains',
	'hanoi1','hanoi2',
	'bubbles',
	'emboss',
	'giza1','giza2',
	'scalpel'
]

def apply_default_settings(options,defaultName)

	# MOUNTAIN
	# automata.rb -wvf -r -u168
	if defaultName == 'mountain' or defaultName == 'mountains'
		options[:rule_number] = 168
		options[:state_random]  = true
		options[:wrap] = true
		options[:transformation_queue] << :reverse
		options[:output_loop_forever] = true
	end

	# HANOI
	# automata.rb -wv -r -u132 -y22
	# automata.rb -wv -r -u164 -y32
	if defaultName =~ /hanoi/
		options[:state_random]  = true
		options[:wrap] = true
		options[:transformation_queue] << :reverse
		if defaultName == 'hanoi2'
			options[:rule_number] = 164
			options[:output_line_count] = 32
		else # defaultName == 'hanoi1'
			options[:rule_number] = 132
			options[:output_line_count] = 22
		end
	end

	# TRIANGLE BUBBLES
	# automata.rb -wv -r -u18 -Y2
	if defaultName == 'bubble' or defaultName == 'bubbles'
		options[:rule_number] = 18
		options[:output_line_begin] = 2
		options[:state_random]  = true
		options[:wrap] = true
		options[:transformation_queue] << :reverse
	end

	# EMBOSSED TRIANGLES
	# automata.rb -wv -r -u57
	# automata.rb -Scvw -r -u99
	if defaultName == 'emboss' or defaultName == 'embossed'
		options[:rule_number] = [57,99].sample
		options[:state_random]  = true
		options[:wrap] = true
		options[:transformation_queue] << :reverse
	end
	
	# GIZA
	# automata.rb -vf -r -u160
	# automata.rb -wvfc -r -u160 -x100 -N90
	# automata.rb -d giza -u164
	if defaultName =~ /giza/
		options[:rule_number] = 160
		options[:state_random]  = true
		options[:state_centred] = true
		options[:wrap] = true
		options[:transformation_queue] << :reverse
		options[:output_loop_forever] = true
		options[:initial_state_length] = options[:cell_count] - 10
		options[:state_random_prob] = [1,14]
	end
	if defaultName == 'giza2'
		options[:rule_number] = 164
	end
	
	# scalpel
	if defaultName == 'scalpel'
		options[:rule_number] = 202
		options[:state_random]  = true
		options[:state_random_mirrored] = true
		options[:wrap] = true
		options[:transformation_queue] << :reverse
		options[:output_loop_forever] = true
		options[:state_random_prob] = [2,1]
	end
	
	# Curtain? Banner?
	# automata.rb -ScUvw -r14,1 -u94 -s' #'
	
end

################################################################################

# Some of these options are set in the form "options[:foo] = !options[:foo]"
# The option list applies each specified option at the point in the option
# list where it occurs. This means that a subsequent option can override or
# alter previous ones. This is most relevant when using the -d option.

optparse = OptionParser.new do |opts|

	# Set a banner, displayed at the top of the help screen.
	opts.banner  = "\n  One-dimensional cellular automaton."
	opts.banner += "\n  http://mathworld.wolfram.com/ElementaryCellularAutomaton.html"
	opts.banner += "\n\n  Usage:  ~nossidge/Code/automata.rb [- options]"
	opts.separator nil

	# Really important stuff.
	opts.on('-x', '--number NUMBER', Integer, 'Number of cells (width of the row)') do |n|
		options[:cell_count] = n if 0 < n
	end
	opts.on('-y', '--lines NUMBER', Integer, 'Number of generation lines to display') do |n|
		options[:output_line_count] = n if 0 < n
	end
	opts.on('-z', '--base NUMBER', Integer, 'Base or radix to use. So 2 for binary, 3 for ternary...') do |n|
		options[:state_count] = n if 1 < n
	end
	opts.separator nil
	
	# Line stuff.
	opts.on('-Y', '--begin NUMBER', Integer, "Line number to begin display. Won't show gens before this") do |n|
		options[:output_line_begin] = n if 0 < n
	end
	opts.on('-f', '--forever', 'Loop forever (or until a repeated state)') do |b|
		options[:output_loop_forever] = !options[:output_loop_forever]
	end
	opts.separator nil
	
	# Multiple line stuff.
	opts.on('-m', '--multi NUMBER', Integer, 'Multiply each line in the output by width') do |n|
		options[:line_multiply] = n if 1 <= n and n <= 255
	end
	opts.on('-M', '--multi-delim STRING', 'Delimiter between each output state when multiline') do |s|
		options[:line_multiply_delim] = s
	end
	opts.separator nil
	
	# Set specific rule(s).
	opts.on('-u', '--rule 30,110', Array, 'Cellular automaton Rule number(s)') do |list|
		options[:rule_number] = []
		options[:rule_number] = each_to_int(list, OptionParser::ParseError)
	end
	
	opts.on('-U', '--rulecool', "Use a random 'cool' Rule. These are uniform and pretty") do |b|
		options[:rule_cool] = !options[:rule_cool]
	end
	opts.separator nil
	
	# Initial state stuff.
	opts.on('-i', '--init STRING', 'Initial state of the automaton') do |s|
		options[:state_value] = s
	end
	opts.on('-c', '--centred', 'Centre the initial state string') do |b|
		options[:state_centred] = !options[:state_centred]
	end

	# Randomised initial state. Optional probability weight array.
	opts.on('-r', '--random [1,2,0]', Array, 'Randomise the initial state') do |list|
		if list
			options[:state_random] = true
			options[:state_random_prob] = each_to_int(list, OptionParser::ParseError)
		else
			options[:state_random] = !options[:state_random]
		end
	end
	opts.separator ' '*39 + "Argument is probability of random state values:"
	opts.separator ' '*39 + "  -r1,1   = even chance between two states (default)"
	opts.separator ' '*39 + "  -r1,3   = 1/4 '0' state, 3/4 '1' state"
	opts.separator ' '*39 + "  -r1,3,2 = 1/6 '0' state, 3/6 '1' state, 2/6 '2' state"
	opts.separator nil
	
	#	Symmetry stuff.
	opts.on('-S', '--symmetry', 'Random initial states are symetrical') do |b|
		options[:state_random_mirrored] = !options[:state_random_mirrored]
	end
	opts.on('-t', '--vert-symmetry', 'Output lines will be reflected vertically') do |b|
		options[:transformation_queue] << :vert_symmetry
	end
	opts.on('-T', '--horiz-symmetry', 'Output lines will be reflected horizontally') do |b|
		options[:transformation_queue] << :horiz_symmetry
	end
	opts.on('-o', '--rotate NUMBER', Integer, 'Rotate by 90 degrees') do |n|
		(n.abs % 4).times { options[:transformation_queue] << :rotation }
	end
	opts.separator nil
	
	#	Random initial state length
	opts.on('-N', '--initnum NUMBER', Integer, "Length of random initial state. Padded by '0' state cells") do |n|
		options[:initial_state_length] = n.abs
	end
	opts.separator ' '*39 + "So, the screen width could be 180, but it will only generate"
	opts.separator ' '*39 + "an initial state of:"
	opts.separator ' '*39 + "  10 = '  o   ooo '"
	opts.separator ' '*39 + "  40 = 'oo o   oo o oo ooo    o  o ooo o ooo   o'"
	opts.separator ' '*39 + "And then that could be centred with -C"
	opts.separator nil
	
	# Other stuff.
	opts.on('-w', '--wrap', 'Wrap horizontally (consider far end cells as neighbours)') do |b|
		options[:wrap] = !options[:wrap]
	end
	opts.on('-v', '--reverse', 'Output generations in reverse order') do |b|
		options[:transformation_queue] << :reverse
	end
	opts.separator nil
	
	# Set the state characters:
	opts.on('-s', '--symbol STRING', 'Characters to use for the states') do |s|
		options[:state_symbols] = s
	end
	opts.separator ' '*39 + "-s' #'  means that state 0 is ' ', state 1 is '#'"
	opts.separator nil
	
	# Default settings.
	opts.on('-d', '--default STRING', defaultNames, 'Select a named default setting from the list:') do |s|
		apply_default_settings(options,s)
		puts s
	end
	opts.separator ' '*39 + default_names_to_output.map{|i|"'#{i}'"}.join(' ')
	opts.separator nil
	
	# pic stuff.
	opts.on('-I', '--image', 'Output to a picture file') do |s|
		options[:image] = !options[:image]
	end
	opts.on('-F', '--imagefile FILENAME', 'Specify the name of the .png file') do |s|
		options[:image_file] = s
	end
	opts.on('-P', '--pixel  NUMBER', Integer, 'Size of pixels (zoom)') do |n|
		options[:pixel_size] = n if 0 < n
	end
	# Colours. Make sure the arguments are integers >= 0 and < 256.
	opts.on('-R', '--red    NUM[,NUM]', Array, 'Red component of image') do |list|
		options[:colour_r] =
			each_to_int(list, OptionParser::ParseError).map { |i| i = i.abs % 256 }
	end
	opts.on('-G', '--green  NUM[,NUM]', Array, 'Green component of image') do |list|
		options[:colour_g] =
			each_to_int(list, OptionParser::ParseError).map { |i| i = i.abs % 256 }
	end
	opts.on('-B', '--blue   NUM[,NUM]', Array, 'Blue component of image') do |list|
		options[:colour_b] =
			each_to_int(list, OptionParser::ParseError).map { |i| i = i.abs % 256 }
	end
	opts.separator nil
	
	# Metadata for the png. This needs to be a string in the form "key1:val1;key2:val2".
	# This will be transformed into a hash.
	opts.on('--metadata STRING', 'Hash of metadata for the .png') do |s|
		begin
			options[:metadata] = s.to_h
		rescue
			raise OptionParser::ParseError, 'Argument must be in the form "key1:val1;key2:val2"'
		end
	end
	opts.separator nil
	
	# Help output.
	opts.on_tail('-h', '--help', 'Display this help screen' ) do
		puts opts, nil
		exit 0
	end
end

# Parse the options and show errors on failure.
begin
	optparse.parse!(ARGV)
rescue OptionParser::ParseError => e
	puts e
	exit 1
end

################################################################################

# Make sure the symbols used don't mess up the image gen.
options[:state_symbols] = STATE_SYMBOLS if options[:image]

# Default probablility is even for all states.
if options[:state_random] and not options[:state_random_prob]
	options[:state_random_prob] = Array.new(options[:state_count]){ |i| 1 }
end

# Use a specific rule, if one (or more) is specified.
if options[:rule_number] != nil
	cells = Cells.new(options[:state_count],options[:cell_count],options[:state_symbols],options[:rule_number])

# Else, use a random rule.
else
	cells = Cells.new(options[:state_count],options[:cell_count],options[:state_symbols])
	cells.cool_rule if options[:rule_cool]
end

# Edge of row wrapping.
cells.wrap = options[:wrap]

# If the user wants a specific starting state.
if options[:state_value] or not options[:state_random]
	
	# Value of the initial state.
	if options[:state_value]
		state_string = options[:state_value]
		
	else
		# Draw a single cell of state 1.
		state_string = '1'
	end
	
# Randomly assign states.
else
	
	# Extend state_random_prob to a state array based on weight.
	state_posibilites = []
	options[:state_random_prob].each_with_index do |count,state|
		count.times do |i|
			state_posibilites << state
		end
	end

	# Use initial_state_length if it is set.
	loops = options[:initial_state_length] ? options[:initial_state_length] : options[:cell_count]

	# If it's mirrored, we need to make sure the string is a palindrome.
	# If not mirrored, just use pick at random for each character.
	state_string = random_string(state_posibilites,loops,options[:state_random_mirrored])
end

# Write the selected state to the centre of the string, if necessary.
# Pad the centred string inbetween 0 state cells.
if options[:state_centred]
	state_string = state_string.center(options[:cell_count],'0')
end

# Set the cells to the value of state_string.
cells.set_all_cells(state_string)

output_lines_by_cell = []

# Times by ten to incorporate the :output_loop_forever option,
#   but still not let it actually loop forever...
#   I should really rename the option...
(1..options[:output_line_count]*10).each do |i|
	
	# Output only after starting line.
	if i >= options[:output_line_begin]
		output_lines_by_cell.push cells.to_a
	end
	cells.compute_next
	
	# Break section.
	if options[:output_loop_forever]
		break if cells.duplicate_state
	else
		break if i > options[:output_line_count]
	end
end

################################################################################

# Set up methods for each transformation type.
def transformation_rotation(int_array_array)
	int_array_array.rotate_right
end
def transformation_reverse(int_array_array)
	int_array_array.reverse
end
def transformation_vert_symmetry(int_array_array)
	output = int_array_array
	int_array_array.reverse[1..-1].each do |i|
		output << i
	end
	output
end
def transformation_horiz_symmetry(int_array_array)
	int_array_array.map do |i|
		i[0...-1] + i.reverse
	end
end

# options[:transformation_queue] contains names of transformation methods.
# Loop through the queue and run each in turn.
options[:transformation_queue].each do |m_name|
	output_lines_by_cell =
		method("transformation_#{m_name}").call(output_lines_by_cell)
end

################################################################################

# Join back up to a string array for output.
array_to_output = []
output_lines_by_cell.each do |line|
	array_to_output << line.join('')
end

# Output the results.
final_output_array = []
array_to_output.each do |i|
	line_with_multi_delim = i + options[:line_multiply_delim]
	line_to_output = line_with_multi_delim * options[:line_multiply]
	if options[:line_multiply_delim].length == 0
		final_output_array << line_to_output
	else
		final_output_array << line_to_output[0...-options[:line_multiply_delim].length]
	end
end

# Output as an image file or as text.
if options[:image]
	require_relative './num_to_pic.rb'
	pic = PicFromNumbers.new(final_output_array)
	pic.image_file = options[:image_file] || "pic_#{cells.rule.to_a.join('_')}.png"
	pic.image_file = options[:image_file] || "pic_#{Time.now.to_i.to_s}.png"
	pic.pixel_size = options[:pixel_size]
	pic.set_colour(options[:colour_r],options[:colour_g],options[:colour_b])
	pic.metadata = options[:metadata]
	pic.generate_image
else
	puts final_output_array
end

# ToDo: Remove debug stuff!
File.open('~rules_used.txt', 'a+') do |f|
	f.puts cells.rule.to_s
end

################################################################################

__END__

ToDo:

-d default options.
Probably should read them in from a file.

Testing
