#! /usr/bin/env ruby

# Parse a few random irc log files from the directories given
# as command line parameters.
files = []
ARGV.each{|arg|
  if (File.directory?(arg))
    Dir.new(arg).each {|f|
        files << f if File.file?(arg + '/' + f)
    }
  elsif (File.file?(arg))
    files << arg
  end
}

puts files.to_s
