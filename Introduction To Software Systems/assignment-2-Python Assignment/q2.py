#!/usr/bin/python3

from bs4 import BeautifulSoup
import requests
from matplotlib import pyplot as plt
import seaborn as sns
import pandas as pd


name = []
genre = []
gross = []
rating = []
runtime = []
year = []
data = {}

with open("q1text.txt", "r") as d:
    for line in d:
        name.append(line.split("--")[0])
        genre.append(line.split("--")[1])
        gross.append(int(line.split("--")[2].replace("$", "").replace(",", "")))
        rating.append(float(line.split("--")[3]))
        runtime.append(int(line.split("--")[4]))
        year.append(int(line.split("--")[5]))

for i in range(1000):
    data[name[i]] = [genre[i], gross[i], rating[i], runtime[i], year[i]]

#sorting by rating - descending
ratings = dict(sorted(data.items(), key=lambda x:(-x[1][2], x[1][3])))
print("Top 100 movies in the descending order of their IMDb rating:")
i=1
for movie in ratings:
    if(i>100):
        break
    print(f"{i}. {movie}")
    i += 1

#prompting user for input
print("\nFilter options:\n1. Duration\n2. Imdb Rating\n3. Year of Release\n4. Genre")
choice = int(input("Enter choice:"))
if choice != 4:
    if choice == 2:
        print("Enter the range:")
        inp = input()
        mini, maxi = inp.split()
        range_min = float(mini)
        range_max = float(maxi)
    else:
        print("Enter the range:")
        inp = input()
        mini, maxi = inp.split()
        range_min = int(mini)
        range_max = int(maxi)
else:
    inp_genre = input("Enter the genre:")

if choice == 1:
    for i in range(1000):
        if runtime[i]>=range_min and runtime[i]<=range_max:
            print(name[i])
elif choice==2:
    for i in range(1000):
        if rating[i]>=range_min and rating[i]<=range_max:
            print(name[i])
elif choice == 3:
    for i in range(1000):
        if year[i]>=range_min and year[i]<=range_max:
            print(name[i]) 
else:
    for i in range(1000):
        if inp_genre in genre[i]:
            print(name[i])
