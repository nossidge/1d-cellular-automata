#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# Basically just an array. Designed to keep iterating forward through
#   the array, looping back to the start when we reach the end.
class LoopedArray
	def initialize(input_array)
		@array = input_array
		@index = -1
	end
	def next
		@index += 1
		@index = 0 if @index >= @array.length
		@array[@index]
	end
	def to_s
		@index = 0 if @index == -1
		@array[@index].to_s
	end
	def to_a
		@array
	end
end

################################################################################
