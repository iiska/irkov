#! /usr/bin/env ruby

require 'rubygems'
require 'net/irc' # net-irc gem

require 'markov_chain'

# Parse a few random irc log files from the directories given
# as command line parameters.
class Irkov < Net::IRC::Client
  def initialize(server,nick,channel,dirs)
    @directories = dirs
    @joined_channels = []
    refresh_markov
    super(server,'6667', {
            :nick => nick,
            :user => nick,
            :real => 'Irkov bot http://github.com/iiska/irkov/'
          })
  end

  def refresh_markov
    files = []
    @directories.each{|arg|
      if (File.directory?(arg))
        Dir.new(arg).each {|f|
          files << arg + '/' + f if File.file?(arg + '/' + f)
        }
      elsif (File.file?(arg))
        files << arg
      end
    }

    selected = []
    20.times{
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

    @markov = MarkovChain.new(lines.join(' '))
  end

  def say
    msg = []
    (4 + rand(10)).times{|c|
      msg << @markov.next(msg[c-1])
    }
    msg.join(' ')
  end

  def on_message(m)
    super
    if (/End of MOTD/.match(m) and (@joined_channels == []))
      post JOIN, "#ossaajat"
      @joined_channels << "#ossaajat"
    elsif (/[Ii]rkov/.match(m) and (@joined_channels.include?('#ossaajat'))) and
        ( !@last_msg_time or ((Time.now - @last_msg_time) > 5))
      post PRIVMSG, "#ossaajat", say
      @last_msg_time = Time.now
    end
  end
end

bot = Irkov.new("irc.opoy.fi", "irkov", "#ossaajat", ARGV)
bot.start
