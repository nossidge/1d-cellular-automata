#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# Common methods. I should wrap this in a module...
################################################################################

# 'name:Paul;instruments:vocals, bass guitar, piano, guitar;dob:1942/06/18'.to_h
# http://billpatrianakos.me/blog/2015/05/31/turn-a-string-into-a-hash-with-string-dot-to-hash-in-ruby/
# Based on the code above, but with validation to exclude nil values.
class String
	def to_h(arr_sep=';', key_sep=':')
		array = self.split(arr_sep)
		hash = {}
		array.each do |e|
			key_value = e.split(key_sep)
			if not key_value[1]
				raise TypeError, 'Hash value must not be nil'
			end
			hash[key_value[0]] = key_value[1]
		end
		hash
	end
end

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
