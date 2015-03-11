#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# One dimensional cellular automaton.
# http://mathworld.wolfram.com/ElementaryCellularAutomaton.html
################################################################################

require 'optparse'
require 'json'

################################################################################

# Add string length to Fixnum.to_s method.
# This will pad with zeroes to get the correct length (if specified).
class Fixnum
	old_to_s = instance_method(:to_s)
	define_method(:to_s) do |base=0,charLen=0|
		oldMethod = (base==0) ? old_to_s.bind(self).() : old_to_s.bind(self).(base)
		('0'*charLen + oldMethod )[-charLen..-1]
  end
end
# Also Bignum? ToDo: Figure out how to do this properly...
class Bignum
	old_to_s = instance_method(:to_s)
	define_method(:to_s) do |base=0,charLen=0|
		oldMethod = (base==0) ? old_to_s.bind(self).() : old_to_s.bind(self).(base)
		('0'*charLen + oldMethod )[-charLen..-1]
  end
end

# Rotate a 2d array by 90 degrees.
class Array
  def rotate_right
    transpose.map &:reverse
  end
end

################################################################################

class Cells
	CHARS = ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
	         'abcdefghijklmnopqrstuvwxyz').split('')

	# The number of cells in the neighbourhood.
	# I haven't experimented with values other than 3 yet.
	Neighbours = 3
	
	# Are we comparing far-left cells with far-right cells?
	attr_accessor :wrap

	# The rule of the automaton in base 10.
	attr_accessor :rule

	# The rule of the automaton in whatever base that @stateCount is set to.
	# This isn't necessarily binary, but it's only a var name...
	attr_accessor :ruleBin
	
	# This will be set to true if the calculated next state is the same as
	#   the current state.
	attr_reader :duplicateState
	
	# @cellArray is an array of integers, representing the current generation.
	
	# @stateSymbols is an array of strings (usually single characters), to
	#   display the state.

  def initialize(stateCount=2,cellCount=11,stateSymbols=CHARS,rule=nil)
    @stateCount = stateCount
    @cellCount = cellCount.to_i
		@stateSymbols = stateSymbols
		@cellArray = Array.new(@cellCount){ |i| 0 }
		@rule = (rule==nil) ? randRule : rule
		@ruleBin = @rule.to_s(@stateCount,state_table_count)
		@duplicateState = false
		@wrap = true
  end
	
	# This is the table to use as the key for a Rule. It will vary by state count.
	# http://mathworld.wolfram.com/images/eps-gif/ElementaryCA30Rules_750.gif
	def state_table
		(state_table_count-1).downto(0).map do |i|
			i.to_s(@stateCount,Neighbours)
		end
	end
	def state_table_count
		@stateCount**Neighbours
	end
	
	# This should work for all state counts.
	def randRule
		allPossibleRuleCount = @stateCount ** (@stateCount ** Neighbours)
		@rule = rand(allPossibleRuleCount)
		@ruleBin = @rule.to_s(@stateCount,state_table_count)
		@rule
	end
	
	# Read in nice regular rules from the file rules.json
	# Examples, for Binary rules:
	# http://plato.stanford.edu/entries/cellular-automata/supplement.html
	def coolRule
		rulesJSON = JSON.parse( open('rules.json').read )
		coolRules = rulesJSON[ @stateCount.to_s ]
		if coolRules
			@rule = coolRules.sample
			@ruleBin = @rule.to_s(@stateCount,state_table_count)
		else
			randRule
		end
		@rule
	end
	
	# Set the state of an individual generation element.
	def setState(elem,value)
		@cellArray[elem] = value
	end
	def array(elem)
		@cellArray[elem]
	end
	
	# Calculate the cells of the next generation.
	def computeNext
		stateNeighbours = '000'
		nextState = false
		cellArrayNextState = Array.new(@cellCount){ |i| 0 }
		
		(0...@cellCount).each do |i|
			stateLeft = 0
			stateThis = @cellArray[i]
			stateRite = 0
			
			# Get states of neighbours.
			if @wrap
				stateLeft = (i==0) ? @cellArray[@cellArray.length-1] : @cellArray[i-1]
				stateRite = (i==(@cellArray.length-1)) ? @cellArray[0] : @cellArray[i+1]
			else
				stateLeft = @cellArray[i-1] if i != 0
				stateRite = @cellArray[i+1] if i != (@cellArray.length-1)
			end
			stateNeighbours = "#{stateLeft}#{stateThis}#{stateRite}"
			
			# Loop backwards.
			(state_table_count-1).downto(0).each do |n|
				state = n.to_s(@stateCount,Neighbours)
				val = @ruleBin[state_table_count-1-n]
				if state == stateNeighbours
					cellArrayNextState[i] = val.to_i
				end
			end
		end
		
		@duplicateState = (@cellArray == cellArrayNextState)
		@cellArray = cellArrayNextState
	end
	
	# Display the state of the generation.
  def display()
		@cellArray.map{|i| @stateSymbols[i]}.join
  end
end

################################################################################

options = {}

# Just to make sure it works on my Windows env.
begin
	options[:cellCount] = `tput cols`.to_i - 1
rescue
	options[:cellCount] = 187
	options[:cellCount] = 166
	options[:cellCount] = 159
	options[:cellCount] = 119
end

options[:outputLineCount] = options[:cellCount] / 2
options[:outputLineBegin] = 1
options[:outputLoopForever] = false

options[:lineMultiply] = 1
options[:lineMultiplyDelim] = ''

options[:ruleNumber] = nil
options[:ruleCool]   = false

options[:stateValue]   = 'o     o'
options[:stateValue]   = nil
options[:stateRandom]  = false
options[:stateCentred] = false
options[:stateRandomMirrored] = false

options[:stateCount] = 2
options[:stateSymbols] = ' o0Oo0Oo0O'
options[:stateSymbols] = ' o()[]{}<>\/'
options[:stateSymbols] = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
options[:stateRandomProb] = nil

options[:wrap] = false
options[:reverse] = false
options[:vertSymmetry] = false
options[:horizSymmetry] = false

options[:initialStateLength] = nil
options[:rotations] = 0

# This is for num_to_pic.rb
options[:image] = false
options[:colourR] = 255
options[:colourG] = 255
options[:colourB] = 255
options[:imageFile] = nil

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
defaultNamesToOutput = [
	'mountains',
	'hanoi1','hanoi2',
	'bubbles',
	'emboss',
	'giza1','giza2',
	'scalpel'
]

def applyDefaultSettings(options,defaultName)

	# MOUNTAIN
	# automata.rb -Rwvf -r168
	if defaultName == 'mountain' or defaultName == 'mountains'
		options[:ruleNumber] = 168
		options[:stateRandom]  = true
		options[:wrap] = true
		options[:reverse] = true
		options[:outputLoopForever] = true
	end

	# HANOI
	# automata.rb -Rwv -r132 -l22
	# automata.rb -Rwv -r164 -l32
	if defaultName =~ /hanoi/
		options[:stateRandom]  = true
		options[:wrap] = true
		options[:reverse] = true
		if defaultName == 'hanoi2'
			options[:ruleNumber] = 164
			options[:outputLineCount] = 32
		else # defaultName == 'hanoi1'
			options[:ruleNumber] = 132
			options[:outputLineCount] = 22
		end
	end

	# TRIANGLE BUBBLES
	# automata.rb -Rwv -r18 -L2
	if defaultName == 'bubble' or defaultName == 'bubbles'
		options[:ruleNumber] = 18
		options[:outputLineBegin] = 2
		options[:stateRandom]  = true
		options[:wrap] = true
		options[:reverse] = true
	end

	# EMBOSSED TRIANGLES
	# automata.rb -Rwv -r57
	# automata.rb -SRCvw -r99
	if defaultName == 'emboss' or defaultName == 'embossed'
		options[:ruleNumber] = [57,99].sample
		options[:stateRandom]  = true
		options[:wrap] = true
		options[:reverse] = true
	end
	
	# GIZA
	# automata.rb -Rvf -r160
	# automata.rb -RwvfC -r160 -n100 -N90
	# automata.rb -d giza -r164
	if defaultName =~ /giza/
		options[:ruleNumber] = 160
		options[:stateRandom]  = true
		options[:stateCentred] = true
		options[:wrap] = true
		options[:reverse] = true
		options[:outputLoopForever] = true
		options[:initialStateLength] = options[:cellCount] - 10
		options[:stateRandomProb] = [1,14]
	end
	if defaultName == 'giza2'
		options[:ruleNumber] = 164
	end
	
	# scalpel
	if defaultName == 'scalpel'
		options[:ruleNumber] = 202
		options[:stateRandom]  = true
		options[:stateRandomMirrored] = true
		options[:wrap] = true
		options[:reverse] = true
		options[:outputLoopForever] = true
		options[:stateRandomProb] = [2,1]
	end
	
	# Curtains?
	# automata.rb -SRCcvw -p'00000000000000000001' -r94
	
end

################################################################################

# This hash will hold all of the command-line options.
optparse = OptionParser.new do |opts|
  
  # Set a banner, displayed at the top of the help screen.
	opts.banner  = "\n  One-dimensional cellular automaton."
	opts.banner += "\n  http://mathworld.wolfram.com/ElementaryCellularAutomaton.html"
  opts.banner += "\n\n  Usage:  ~nossidge/Code/automata.rb [- options]"
	opts.separator nil

	# Really important stuff.
	opts.on('-x', '--number NUMBER', Integer, 'Number of cells (width of the row)') do |n|
		options[:cellCount] = n if 0 < n
	end
	opts.on('-y', '--lines NUMBER', Integer, 'Number of generation lines to display') do |n|
		options[:outputLineCount] = n if 0 < n
	end
	opts.on('-z', '--base NUMBER', Integer, 'Base or radix to use. So 2 for binary, 3 for ternary...') do |n|
		options[:stateCount] = n if 1 < n
	end
	opts.separator nil
	
	# Line stuff.
	opts.on('-Y', '--begin NUMBER', Integer, "Line number to begin display. Won't show gens before this") do |n|
		options[:outputLineBegin] = n if 0 < n
	end
	opts.on('-f', '--forever', 'Loop forever (or until a repeated state)') do |b|
		options[:outputLoopForever] = !options[:outputLoopForever]
	end
	opts.separator nil
	
	# Multiple line stuff.
	opts.on('-m', '--multi NUMBER', Integer, 'Multiply each line in the output by width') do |n|
		options[:lineMultiply] = n if 1 <= n and n <= 255
	end
	opts.on('-M', '--multi-delim STRING', 'Delimiter between each output state when multiline') do |s|
		options[:lineMultiplyDelim] = s
	end
	opts.separator nil
	
	# Rule stuff.
	opts.on('-u', '--rule NUMBER', Integer, 'Elementary cellular automaton Rule number') do |n|
		options[:ruleNumber] = n if 0 <= n
	end
	opts.on('-U', '--rulecool', "Use a random 'cool' Rule. These are uniform and pretty") do |b|
		options[:ruleCool] = !options[:ruleCool]
	end
	opts.separator nil
	
	# Initial state stuff.
	opts.on('-i', '--init STRING', 'Initial state of the automaton') do |s|
		options[:stateValue] = s
	end
	opts.on('-c', '--centred', 'Centre the initial state string') do |b|
		options[:stateCentred] = !options[:stateCentred]
	end

	# Randomised initial state. Optional probability weight array.
	opts.on('-r', '--random [1,2,0]', Array, 'Randomise the initial state') do |list|
		options[:stateRandom] = !options[:stateRandom]
		if options[:stateRandom] and list
			options[:stateRandomProb] = []

			# Error if an argument is not an integer.
			list.each do |elem|
				begin
					options[:stateRandomProb] << Integer(elem).abs
				rescue ArgumentError => e
					raise OptionParser::ParseError
				end
			end
		end
	end
	opts.separator ' '*39 + "Argument is probability of random state values:"
	opts.separator ' '*39 + "  -p1,1   = even chance between two states (default)"
	opts.separator ' '*39 + "  -p1,3   = 1/4 '0' state, 3/4 '1' state"
	opts.separator ' '*39 + "  -p1,3,2 = 1/6 '0' state, 3/6 '1' state, 2/6 '2' state"
	opts.separator nil
	
#	Symmetry stuff.
	opts.on('-S', '--symmetry', 'Random initial states are symetrical') do |b|
		options[:stateRandomMirrored] = !options[:stateRandomMirrored]
	end
	opts.on('-t', '--vert-symmetry', 'Output lines will be reflected vertically') do |b|
		options[:vertSymmetry] = !options[:vertSymmetry]
	end
	opts.on('-T', '--horiz-symmetry', 'Output lines will be reflected horizontally') do |b|
		options[:horizSymmetry] = !options[:horizSymmetry]
	end
	opts.on('-o', '--rotate NUMBER', Integer, 'Rotate by 90 degrees') do |n|
		options[:rotations] = n.abs % 4
	end
	opts.separator nil
	
	#	Random initial state length
	opts.on('-N', '--initnum NUMBER', Integer, "Length of random initial state. Padded by '0' state cells") do |n|
		options[:initialStateLength] = n.abs
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
		options[:reverse] = !options[:reverse]
	end
	opts.separator nil
	
	# Set the state characters:
	opts.on('-s', '--symbol STRING', 'Characters to use for the states') do |s|
		options[:stateSymbols] = s
	end
	opts.separator ' '*39 + "-s' #'  means that state 0 is ' ', state 1 is '#'"
	opts.separator nil
	
	# Default settings.
	opts.on('-d', '--default STRING', defaultNames, 'Select a named default setting from the list:') do |s|
		applyDefaultSettings(options,s)
		puts s
	end
	opts.separator ' '*39 + defaultNamesToOutput.map{|i|"'#{i}'"}.join(' ')
	opts.separator nil
	
	# pic stuff.
	opts.on('-I', '--image', 'Output to a picture file') do |s|
		options[:image] = !options[:image]
	end
	opts.on('-F', '--imagefile FILENAME', 'Specify the name of the .png file') do |s|
		options[:imageFile] = s
	end
	opts.on('-R', '--red NUMBER', Integer, 'Red component of image') do |n|
		options[:colourR] = n if 0 <= n and n <= 255
	end
	opts.on('-G', '--green NUMBER', Integer, 'Green component of image') do |n|
		options[:colourG] = n if 0 <= n and n <= 255
	end
	opts.on('-B', '--blue NUMBER', Integer, 'Blue component of image') do |n|
		options[:colourB] = n if 0 <= n and n <= 255
	end
	opts.separator nil
	
	# Help stuff.
  opts.on_tail('-h', '--help', 'Display this help screen' ) do
    puts opts, nil
    exit 0
  end
end

begin
	optparse.parse!(ARGV)
rescue OptionParser::ParseError => e
	puts e
	exit 1
end

################################################################################

# Default probablility is even for all states.
if options[:stateRandom] and not options[:stateRandomProb]
	options[:stateRandomProb] = Array.new(options[:stateCount]){ |i| 1 }
end

# Use a specific rule, if one is specified.
if options[:ruleNumber] != nil
	cells = Cells.new(options[:stateCount],options[:cellCount],options[:stateSymbols],options[:ruleNumber])

# Else, use a random rule.
else
	cells = Cells.new(options[:stateCount],options[:cellCount],options[:stateSymbols])
	cells.coolRule if options[:ruleCool]
end

# Edge of row wrapping.
cells.wrap = options[:wrap]

# If the user wants a specific starting state.
if options[:stateValue] or not options[:stateRandom]
	
	# Value of the initial state.
	if options[:stateValue]
		stateString = options[:stateValue]
		
	else
		# Draw a single cell of state 1.
		stateString = '1'
	end
	
# Randomly assign states.
else
	
	# Extend stateRandomProb to a state array based on weight.
	statePosibilites = []
	options[:stateRandomProb].each_with_index do |count,state|
		count.times do |i|
			statePosibilites << state
		end
	end

	# Use initialStateLength if it is set.
	loops = options[:initialStateLength] ? options[:initialStateLength] : options[:cellCount]
	stateString = ''

	# If it's mirrored we need to do different stuff.
	if options[:stateRandomMirrored]

		# If the length is odd.
		isOdd = loops % 2 == 0 ? false : true
		loops = loops / 2
		stateString = statePosibilites.sample if isOdd

		# Start from the middle of the string, and work our way to the edge.
		(0...loops).each do |i|
			randChar = statePosibilites.sample
			stateString = randChar + stateString + randChar
		end
		
	# Not mirrored.
	else
		(0...loops).each do |i|
			stateString += statePosibilites.sample.to_s
		end
	end
	
end

# Write the selected state to the centre of the string, if necessary.
# Pad the centred string inbetween 0 state cells.
if options[:stateCentred]
	stateString = stateString.center(options[:cellCount],'0')
end

# Traverse stateString and assign to each cell.
(0...stateString.length).each do |i|
	cells.setState(i, stateString[i].to_i )
end

outputLinesByCell = []

# Times by ten to incorporate the :outputLoopForever option,
#   but still not let it actually loop forever...
#   I should really rename the option...
(1..options[:outputLineCount]*10).each do |i|
	
	# Output only after starting line.
	if i >= options[:outputLineBegin]
		outputLinesByCell.push cells.display().split('')
	end
	cells.computeNext
	
	# Break section.
	if options[:outputLoopForever]
		break if cells.duplicateState
	else
		break if i > options[:outputLineCount]
	end
end

################################################################################

# Rotate if necessary.
options[:rotations].times do |i|
	outputLinesByCell = outputLinesByCell.rotate_right
end

# Join back up to a string array for output.
outputLines = []
outputLinesByCell.each do |line|
	outputLines << line.join('')
end

################################################################################

# Line output. Handle reversal if necessary.
arrayToOutput = options[:reverse] ? outputLines.reverse : outputLines

# Line output. Handle vertical symmetry if necessary.
if options[:vertSymmetry]
	newOutput = arrayToOutput
	arrayToOutput.reverse[1..-1].each { |i| newOutput << i }
	arrayToOutput = newOutput
end

# Line output. Handle horizontal symmetry if necessary.
if options[:horizSymmetry]
	newOutput = []
	arrayToOutput.each do |i|
		newLine = (i[0...-1] + i.reverse).to_s
		newOutput.push(newLine)
	end
	arrayToOutput = newOutput
end

# Output the results.
finalOutputArray = []
arrayToOutput.each do |i|
	lineWithMultiDelim = i + options[:lineMultiplyDelim]
	lineToOutput = lineWithMultiDelim * options[:lineMultiply]
	if options[:lineMultiplyDelim].length == 0
		finalOutputArray << lineToOutput
	else
		finalOutputArray << lineToOutput[0...-options[:lineMultiplyDelim].length]
	end
end

# Output as an image file or as text.
if options[:image]
	require_relative './num_to_pic.rb'
	pic = PicFromNumbers.new(finalOutputArray)
	pic.imageFile = options[:imageFile] || "pic_#{cells.rule.to_s}.png"
	pic.set_colour(options[:colourR],options[:colourG],options[:colourB])
	pic.generate_image
else
	puts finalOutputArray
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

OOP - Make this an includable class as well as console runnable.
