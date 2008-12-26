#! /usr/bin/env ruby

require 'markov_chain'

# Parse a few random irc log files from the directories given
# as command line parameters.
files = []
ARGV.each{|arg|
  if (File.directory?(arg))
    Dir.new(arg).each {|f|
        files << arg + '/' + f if File.file?(arg + '/' + f)
    }
  elsif (File.file?(arg))
    files << arg
  end
}

selected = []
5.times{
  selected << files.delete_at(rand(files.size))
}

lines = []
re = Regexp.new('^\d\d:\d\d +<.+> +(.*)$')
selected.each{|f|
  File.new(f).each{|l|
    m = re.match(l)
    lines << m[1] if m
  }
}

m = MarkovChain.new(lines.join(' '))

msg = []
(4 + rand(10)).times{|c|
  msg << m.next(msg[c-1])
}

puts msg.join(' ')
