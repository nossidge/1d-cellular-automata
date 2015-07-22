#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# Common methods. I should wrap this in a module...
################################################################################

# Convert an input array to Integer, and raise an error if not possible.
def each_to_int(input_array, error_to_raise)
	output_array = []
	input_array.each do |elem|
		begin
			output_array << Integer(elem)
		rescue ArgumentError => e
			raise error_to_raise
		end
	end
	output_array
end

################################################################################
