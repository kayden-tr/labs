def shortest_vowel_word(words):
    return min([len(w) for w in words if w[0] in 'aeiou'], default=None)

words = ['apple', 'banana', 'orange', 'umbrella', 'grape']

print(shortest_vowel_word(words))