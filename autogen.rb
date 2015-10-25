#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# Generate random permutations of automata.rb options.
# No Ruby module API, just generate the console args and run via `backticks`.
# WARNING: This code is very rough and ready. Hideous, in fact.
################################################################################

require 'weighted_randomizer'

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

def count_rule_possibilities(state_count,neighbours=3)
	state_count ** (state_count ** neighbours)
end

################################################################################

def make_picture
	
	# Create a bell-curve for randomness.
	base = { 2 => 2, 3 => 3, 4 => 2, 5 => 1 }
	base = WeightedRandomizer.new(base).sample
#	base = 4
	
	rule_count = rand(1..4)
	rules = []
	rule_count.times do
		rules << rand(1..count_rule_possibilities(base))
	end
	
	base_opt       = " -z#{base}"
	rule_opt       = " -u#{rules.join(',')}"
	
	centre_opt     = [true,false].sample ? ' -c' : ''
	wrap_opt       = [true,false].sample ? ' -w' : ''
	reverse_opt    = [true,false].sample ? ' -v' : ''
	
	
#	centre_opt     = ' -c'
#	wrap_opt       = ' -w'
#	reverse_opt    = ' -v'
	
	
	
	
	# Rotation and tiling.
	rotations = {
		' -ttTT' => 10,
		' -ttTo1' => 10,
		' -tttTo1' => 10,
		' -tttTTo1' => 0,
		' -tttTT' => 0,
		'' => 20,
		' -o1' => 0
	}
	rotation_opt = WeightedRandomizer.new(rotations).sample
	rotation_small = ( rotation_opt == '' or rotation_opt == ' -o1' )

	# Size depends on the chosen rotation.
	multi = rotation_small ? 4 : 1
	dim_x = rand(30..60) * multi
	dim_y = rand(30..60) * multi
	sub_string_len = dim_x - (rand(0..20) * multi)  # -N
	
	dim_x_opt     = " -x#{dim_x}"
	dim_y_opt     = " -y#{dim_y}"
	
	# Create the initial string
	symmetry       = [true,false].sample
	random         = [true,false].sample
	
	# Make sure there's something in the array.
	char_array = []
	loop do 
		char_array = base.times.map { |i|
			i.to_s * rand(0..3)
		}.join.split('')
		break if !char_array.empty?
	end
	
	
	init_str = random_string(char_array, sub_string_len, symmetry, true, dim_x, buffer_char='0')
	init_opt = " -i#{init_str}"
	
	
	

	# Many colours is nice, but also crazy, so don't do it too often.
	colours = { 1 => 30, 2 => 20, 3 => 10, 4 => 1, 5 => 1, 6 => 1, 7 => 1, 8 => 1 }
	colours = WeightedRandomizer.new(colours).sample
	
	
	colour_r = colours.times.map{ rand(0..255) }
	colour_g = colours.times.map{ rand(0..255) }
	colour_b = colours.times.map{ rand(0..255) }
	colour_r_opt = " -R#{colour_r.join(',')}"
	colour_g_opt = " -G#{colour_g.join(',')}"
	colour_b_opt = " -B#{colour_b.join(',')}"
	pix_zoom_opt = " -p4"
	invert_opt   = [true,false].sample ? ' --invert' : ''

	command  = 'ruby automata.rb'
	command += base_opt
	command += dim_x_opt
	command += dim_y_opt
	command += rule_opt
	command += centre_opt
	command += wrap_opt
	command += reverse_opt
	command += rotation_opt
	command += colour_r_opt
	command += colour_g_opt
	command += colour_b_opt
	command += pix_zoom_opt
	command += invert_opt
	
	command += init_opt
	
	
	command += " -I -F pic_#{Time.now.to_i.to_s}.png"
	puts command



	# Add the png metadata to the file.
	# So you can find the exact command to generate the exact png.
	command = "#{command} --metadata 'automata:#{command}'"
	
	# Run the damn thing.
	`#{command}`
end


#20.times { make_picture }
#100.times { make_picture }
100.times { make_picture }

################################################################################
