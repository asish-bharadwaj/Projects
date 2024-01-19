#!/usr/bin/python3

from matplotlib import pyplot as plt
from wordcloud import WordCloud
import pandas as pd

with open("sh.txt", "r") as f:
    data = f.read()
    data = data.replace(",", " ").replace(".", " ").replace("'", " ").replace("/", " ").replace("(", " ").replace(")", " ").replace("-", " ").replace("!", " ").replace('"', ' ').replace(":", " ").replace("?", " ").replace(";", " ").replace("*", " ").lower()
    with open("stopwords.txt", "r") as s:
        stop = s.read()
        stopwords = stop.split()
        words = data.split()
        for j in range(len(words)):
            for i in range(len(stopwords)):
                if words[j] == stopwords[i]:
                    words[j] = " "
    
with open("sh.txt", "w") as f:
    for i in range(len(words)):
        if words[i] != " ":
            f.write(words[i])
            f.write(" ")

with open("sh.txt", "r") as data:
    text = data.read()
wc = WordCloud(background_color="white", height=800, width = 800).generate(text)
plt.figure(figsize=(8, 8))

plt.imshow(wc, interpolation="bilinear")
plt.axis("off")
plt.savefig("wordcloud.png")

words = text.split()
word_count = pd.Series(words).value_counts()
most_common_word = {}

total_chars = 0
for word in words:
    total_chars+=len(word)
    if word in most_common_word:
        most_common_word[word] += 1
    else:
        most_common_word[word] = 1

most = dict(sorted(most_common_word.items(), key=lambda x:-x[1]))
avg_word_len = total_chars/len(words)
first_key = next(iter(most))
print(first_key, avg_word_len)
