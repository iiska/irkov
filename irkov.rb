#! /usr/bin/env ruby

require 'rubygems'
require 'net/irc' # net-irc gem
require 'yaml'

require 'markov_chain'

# Parse a few random irc log files from the directories given
# as command line parameters.
class Irkov < Net::IRC::Client
  def initialize(config_file)
    @config = YAML::load(File.open(config_file))
    @joined_channels = []
    refresh_markov
    super(@config['server'],@config['port'], {
            :nick => @config['nick'],
            :user => @config['nick'],
            :real => @config['realname']
          })
  end

  def refresh_markov
    files = []
    @config['logdirs'].each{|arg|
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

  def say(w)
    msg = [@markov.next(w)]
    (4 + rand(10)).times{|c|
      msg << @markov.next(msg[c-1])
    }
    msg.join(' ')
  end

  def on_message(m)
    super
    p m
    if (/End of MOTD/.match(m) and (@joined_channels == []))
      post JOIN, @config['channel']
      @joined_channels << @config['channel']
    elsif (/[Ii]rkov/.match(m) and (@joined_channels.include?(@config['channel']))) and
        ( !@last_msg_time or ((Time.now - @last_msg_time) > 5))
      post PRIVMSG, @config['channel'], say
      @last_msg_time = Time.now
    end
  end
end

config_file = [ARGV[0],
               './config.yml',
               './irkovrc',
               '~/.irkovrc'].select{|f|
  f && File.file?(f)
}.first

if config_file
  Irkov.new(config_file).start
else
  puts "No config file found."
end
