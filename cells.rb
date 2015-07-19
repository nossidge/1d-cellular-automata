#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# Class structure for a one dimensional cellular automaton.
# Supports multiple cell states (not just 0 and 1).
# Cell mutation circumstance limited to itself and two immediate neighbours.
#
# Reference:
# https://en.wikipedia.org/wiki/Elementary_cellular_automaton
# http://mathworld.wolfram.com/ElementaryCellularAutomaton.html
################################################################################

require_relative 'looped_array.rb'

################################################################################

# Add string length to Fixnum.to_s method.
# This will pad with zeroes to get the correct length (if specified).
class Fixnum
	old_to_s = instance_method(:to_s)
	define_method(:to_s) do |base=0,char_len=0|
		old_method = (base==0) ? old_to_s.bind(self).() : old_to_s.bind(self).(base)
		('0'*char_len + old_method )[-char_len..-1]
	end
end
# Also Bignum? ToDo: Figure out how to do this properly...
class Bignum
	old_to_s = instance_method(:to_s)
	define_method(:to_s) do |base=0,char_len=0|
		old_method = (base==0) ? old_to_s.bind(self).() : old_to_s.bind(self).(base)
		('0'*char_len + old_method )[-char_len..-1]
	end
end

################################################################################

# This is just the cells in a SINGLE dimension, i.e. for one line.
# It does not store the history of previous cell states.
# You need to call #to_a or #to_s to return each state, and #compute_next to
#   move to the next state in the sequence.
class Cells
	CHARS = ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
	         'abcdefghijklmnopqrstuvwxyz')

	# The number of cells in the neighbourhood.
	# I haven't experimented with values other than 3 yet.
	Neighbours = 3
	
	# The number of cells.
	attr_reader :cell_count
	
	# Are we comparing far-left cells with far-right cells?
	attr_accessor :wrap

	# The rule of the automaton in base 10.
	attr_reader :rule

	# The rule of the automaton in whatever base that @state_count is set to.
	# This isn't necessarily binary, but it's only a var name...
	attr_reader :rule_bin
	
	# This will be set to true if the calculated next state is the same as
	#   the current state.
	attr_reader :duplicate_state
	
	# @cell_array is an array of integers, representing the current generation.
	
	# @state_symbols is an array of strings (usually single characters), to
	#   display the state.

	def initialize(state_count=2, cell_count=11, state_symbols=CHARS, rule=nil)
		@state_count = state_count
		@cell_count = cell_count.to_i
		@state_symbols = state_symbols.split('')
		@cell_array = Array.new(@cell_count){ |i| 0 }
		@duplicate_state = false
		@wrap = true
		if rule == nil
			rand_rule
		else
			self.rule = rule
		end
	end
	
	# When setting a rule, also calculate the binary string representation.
	# Also mod by 256, or whatever is the max rule count for the dimension.
	def rule=(input_rule)
		array_rule     = [*input_rule].map {|i| i % count_rule_possibilities}
		array_rule_bin = array_rule.map do |r|
			r.to_s(@state_count,self.state_table_count)
		end
		@rule     = LoopedArray.new(array_rule)
		@rule_bin = LoopedArray.new(array_rule_bin)
	end
	
	# This is the table to use as the key for a Rule. It will vary by state count.
	# http://mathworld.wolfram.com/images/eps-gif/ElementaryCA30Rules_750.gif
	def state_table
		(self.state_table_count-1).downto(0).map do |i|
			i.to_s(@state_count,Neighbours)
		end
	end
	def state_table_count
		@state_count ** Neighbours
	end
	
	# All possible rules for the cell state and lookup cell neighbour counts.
	def count_rule_possibilities
		@state_count ** (@state_count ** Neighbours)
	end
	
	# This should work for all state counts.
	# rule_count is the number of random rules to generate.
	def rand_rule(rule_count=1)
		self.rule = rule_count.times.map do
			rand(count_rule_possibilities)
		end
	end
	
	# Read in nice regular rules from the file rules.json
	# Examples, for Binary rules:
	# http://plato.stanford.edu/entries/cellular-automata/supplement.html
	def cool_rule
		rules_JSON = JSON.parse( open('rules.json').read )
		cool_rules = rules_JSON[ @state_count.to_s ]
		if cool_rules
			self.rule = cool_rules.sample
		else
			rand_rule
		end
		@rule
	end
	
	# Set the state of an individual generation element.
	def set_state(elem,value)
		@cell_array[elem] = value
	end
	
	# Should do more validation of state symbols...
	def set_all_cells(full_state)
		
		# Reject if it's the wrong length.
		if full_state.length != @cell_count
			raise 'Wrong length for cell array'
		else
			
			# If it's a string, make it an array.
			if full_state.is_a?(String)
				full_state = full_state.split('')
			end
			@cell_array = full_state
		end
		
		self.to_s
	end
	
	# Set a single centred '1' cell between '0' cells.
	def set_single_cell_centred
		set_all_cells('1'.center(@cell_count,'0'))
	end
	
	# Calculate the cells of the next generation.
	# This is hard-coded to use 3 neighbouring cells.
	# I do want this to be configurable in the future.
	def compute_next
		state_neighbours = '000'
		cell_array_next_state = Array.new(@cell_count){ |i| 0 }
		
		# Get the rule string for this generation.
		rule_bin_current = @rule_bin.next
		
		# Calculate the next state for each cell.
		(0...@cell_count).each do |i|
			state_left  = 0
			state_this  = @cell_array[i]
			state_right = 0
			
			# Get states of neighbours.
			# Wrap far left and far right cells, if wrap is specified.
			# If not, set the 'void' cell to be 0 state.
			if @wrap
				state_left  = (i==0) ? @cell_array[@cell_array.length-1] : @cell_array[i-1]
				state_right = (i==(@cell_array.length-1)) ? @cell_array[0] : @cell_array[i+1]
			else
				state_left  = @cell_array[i-1] if i != 0
				state_right = @cell_array[i+1] if i != (@cell_array.length-1)
			end
			state_neighbours = "#{state_left}#{state_this}#{state_right}"
			
			# Loop backwards.
			(self.state_table_count-1).downto(0).each do |n|
				state = n.to_s(@state_count,Neighbours)
				val = rule_bin_current[self.state_table_count-1-n]
				if state == state_neighbours
					cell_array_next_state[i] = val.to_i
				end
			end
		end
		
		# True if the new state is the same as the last one.
		# If the rule does not change, this will be the same
		#   state for all future generations.
		@duplicate_state = (@cell_array == cell_array_next_state)
		
		@cell_array = cell_array_next_state
		self.to_s
	end
	
	# Output the current generation.
	def to_a
		@cell_array.map{|i| @state_symbols[i.to_i]}
	end
	def to_s
		to_a.join
	end
end

################################################################################

__END__

Example:
cells = Cells.new(2,21,' o',30)
puts cells.set_all_cells('000000000010000000000')
10.times do
	puts cells.compute_next
end
