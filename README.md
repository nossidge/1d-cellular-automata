# One dimensional cellular automata
by Paul Thompson - nossidge@gmail.com - tilde.town/~nossidge

One dimensional cellular automata. Supports multiple cell states. Output to stdout and .png image.

**This is so unfinished it's just like wow.**

http://mathworld.wolfram.com/ElementaryCellularAutomaton.html

# Tutorial

A tutorial for the console.

Let's create an output using just the -x and -y options to specify the size:
```
$ automata.rb -x37 -y7
1000000000000000000000000000000000000
0100000000000000000000000000000000000
1010000000000000000000000000000000000
0001000000000000000000000000000000000
0010100000000000000000000000000000000
0100010000000000000000000000000000000
1010101000000000000000000000000000000
0000000100000000000000000000000000000
```
This writes a single true '1' cell at the leftmost character of the first row, and applies a random rule to generate 6 more generations. The random rule used for this is rule 146. Each time a automaton is generated, the rule number is saved to a file called `~rules.txt` so you can see which rule was most recently used.


We can use the `-u` option to choose a specific rule, so let's use `-u146` so we can compare future output using the same rule. We will now use the `-c` option to centre the initial '1' cell in the middle of the input row.
```
$ automata.rb -x37 -y7 -u146 -c
0000000000000000001000000000000000000
0000000000000000010100000000000000000
0000000000000000100010000000000000000
0000000000000001010101000000000000000
0000000000000010000000100000000000000
0000000000000101000001010000000000000
0000000000001000100010001000000000000
0000000000010101010101010100000000000
```

The default output symbols are 01234... for each cell state. But we can overwrite this using the `-s` option. Let's make all _zero_ states a space, and all _one_ states a lowercase O.
```
$ automata.rb -x37 -y7 -u146 -c -s' o'
                  o
                 o o
                o   o
               o o o o
              o       o
             o o     o o
            o   o   o   o
           o o o o o o o o
```

That looks pretty cool. You can also use the `-v` option to flip the output so that the oldest generations are displayed last:
```
$ automata.rb -x37 -y7 -u146 -c -s' o' -v
           o o o o o o o o
            o   o   o   o
             o o     o o
              o       o
               o o o o
                o   o
                 o o
                  o
```

The `-t` option is used to add Y-axis symmetry to the output:
```
$ automata.rb -x37 -y7 -u146 -c -s' o' -t
                  o
                 o o
                o   o
               o o o o
              o       o
             o o     o o
            o   o   o   o
           o o o o o o o o
            o   o   o   o
             o o     o o
              o       o
               o o o o
                o   o
                 o o
                  o
```
```
$ automata.rb -x37 -y7 -u146 -c -s' o' -tv
           o o o o o o o o
            o   o   o   o
             o o     o o
              o       o
               o o o o
                o   o
                 o o
                  o
                 o o
                o   o
               o o o o
              o       o
             o o     o o
            o   o   o   o
           o o o o o o o o
```

Instead of using a single _one_ cell as the initial state, we can specify whatever state we want, by using the `-i` option. The `-c` option works here as well, so we can use it to write `'o     o'` to the centre of the initial state:
```
$ automata.rb -x37 -y7 -u146 -c -s' o' -i'o     o'
               o     o
              o o   o o
             o   o o   o
            o o o   o o o
           o     o o     o
          o o   o   o   o o
         o   o o o o o o   o
        o o o           o o o
```

Or you could just let it randomly create an initial state, with the `-r` option:
```
$ automata.rb -x37 -y7 -u146 -c -s' o' -r
  oooo oo   o o o   ooo o o o o o o
 o oo    o o     o o o             o
o    o  o   o   o     o           o o
 o  o oo o o o o o   o o         o
o oo              o o   o       o o
    o            o   o o o     o   o
   o o          o o o     o   o o o o
  o   o        o     o   o o o
```

The `-N` option lets you constrain the randomised initial state to just a few cells, leaving the rest with state _zero_. So to randomise just the centremost 15 cells:
```
$ automata.rb -x37 -y7 -u146 -c -s' o' -r -N15
           o   o  oo   o
          o o o oo  o o o
         o        oo     o
        o o      o  o   o o
       o   o    o oo o o   o
      o o o o  o        o o o
     o       oo o      o     o
    o o     o    o    o o   o o
```

And you can use the `-p` option to specify the probablility of each option. This chooses state _one_ 90% of the time, and _zero_ the remainder:
```
$ automata.rb -x37 -y7 -u146 -c -s' o' -r -p'0111111111'
o oooooooooo ooooo oooooooo ooooooooo
   oooooooo   ooo   oooooo   ooooooo
  o oooooo o o o o o oooo o o ooooo o
 o   oooo             oo       ooo
o o o oo o           o  o     o o o
          o         o oo o   o     o
         o o       o      o o o   o o
        o   o     o o    o     o o
```

I'm going to use the initial state of that last example to show the `-w` option. This wraps the screen, so that the far-left cell will take into account the value of the far-right cell and vice versa.
```
$ automata.rb -x37 -y7 -u146 -c -s' o' -r -i'o oooooooooo ooooo oooooooo ooooooooo' -w
o oooooooooo ooooo oooooooo ooooooooo
   oooooooo   ooo   oooooo   oooooooo
o o oooooo o o o o o oooo o o oooooo
     oooo             oo       oooo
    o oo o           o  o     o oo o
   o      o         o oo o   o      o
o o o    o o       o      o o o    o
     o  o   o     o o    o     o  o
```

Now you can start to see the pretty, chaotic patterns that can be generated with just these simple rules!
