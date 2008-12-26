# Basic class for Markov chain with any text input.
# Some ideas taken from: http://www.ruby-forum.com/topic/61303
#
# @words is lookup table for each word,
# which contains hashes of amounts for next words.

class MarkovChain
  def initialize(text)
    @words = Hash.new

    a = text.split
    a.each_with_index{|w,i|
      add(w, a[i-1]) if i <= a.size-2
    }
  end

  def add(w, n)
    if (!@words[w])
      @words[w] = Hash.new(0) # initialize new hash with defaul value 0
    end
    @words[w][n] += 1
  end

  def next(w)
    w =  @words.keys[rand(@words.keys.size)] if !w
    return "" if !@words[w]
    next_words = @words[w]

    sum = next_words.inject(0) {|sum,v| sum += v[1]}
    r = rand(sum) + 1
    next_word = next_words.find{|k,v|
      sum -= v
      sum <= r
    }.first

    next_word
  end
end
