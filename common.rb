#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# Common methods. I should wrap this in a module...
################################################################################

# Convert each element in an input array to Integer, and raise an error if the
#   conversion to Int is not possible for any element.
def each_to_int(input_array, error_to_raise=TypeError)
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
