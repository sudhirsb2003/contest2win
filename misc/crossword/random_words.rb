#!/usr/bin/ruby -w

class Array
	def rand_elem
		self[rand(size)]
	end
end

# Open and read the dictionary.
dict = IO.readlines("/usr/share/dict/words")

# Pick a random word with 6 letters.
20.times {
baseWord = dict[rand dict.size]
print baseWord.upcase
}
