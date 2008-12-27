#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

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
    40.times{
      selected << files.delete_at(rand(files.size))
    }

    lines = []
    # Regexp is for irssi log format. http://irssi.org
    re = Regexp.new('^\d\d:\d\d +<.+> +(.*)$')
    # Match case insensitive normal finnish words, which may end
    # to . , ! or ?
    normal_word = Regexp.new('([a-zäöå\344\366][a-zäöå\344\366]+)[\.,?!]?', true)
    selected.each{|f|
      File.new(f).each{|l|
        m = re.match(l)
        # Make all normal words downcase, and remove , . ! or ? from the end
        s = m[1].split(' ').map{|w|
          n = normal_word.match(w)
          if n
            n[1].downcase
          else
            w
          end
        } if m
        lines << s.join(' ') if m
      }
    }

    @markov = MarkovChain.new(lines)
  end

  def say
    msg = []
    while msg == [] do
      msg = []
      (6 + rand(10)).times{|c|
        s = @markov.next(msg[c-1])
        if s == ''
          break
        else
          msg << s
        end
      }
    end
    msg.join(' ')
  end

  def on_message(m)
    super
    # This may be network dependant but at least in IRCnet End of MOTD
    # is command 376.
    #if (/End of MOTD/.match(m) and (@joined_channels == []))
    if (m.command == '376') and (@joined_channels == [])
      post JOIN, @config['channel']
      @joined_channels << @config['channel']
    elsif (m.command == PRIVMSG) and
        ( !@last_msg_time or ((Time.now - @last_msg_time) > 1))
      channel, msg = m.params
      re = Regexp.new(@config['nick'], true)
      if re.match(msg) and !re.match(channel)
        post PRIVMSG, channel, say
        @last_msg_time = Time.now
      elsif re.match(channel)
        channel = /^(.+)!/.match(m.prefix)[1]
        post PRIVMSG, channel, say
        @last_msg_time = Time.now
      end
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
  p Irkov.new(config_file).say#.start
else
  puts "No config file found."
end
