#!/usr/bin/python3

from bs4 import BeautifulSoup
import requests
from matplotlib import pyplot as plt
import seaborn as sns
import pandas as pd

url = "https://www.imdb.com/list/ls098063263/?st_dt=&mode=detail&page=10&sort=list_order,asc"


#extracting base url to iterate over all pages, starting from the 1st page
base_url = url.split("?")[0]
params = url.split("?")[1].split("&")
params_dict = {}
urls = {}
#declaring name, genre, gross lists - to be used later
name = []
genre = []
gross = []
rating = []
runtime = []
year = []
for param in params:
    key, value = param.split("=")
    params_dict[key] = value 

for i in range(1, 11):
    params_dict["page"] = str(i)
    new_url = base_url + "?" + "&".join([f"{key}={value}" for key, value in params_dict.items()])
    urls[i] = new_url

# collecting name, genre, gross and storing to respective lists
for j in range(1, 11):
    r = requests.get(urls[j])
    doc = BeautifulSoup(r.content, "html.parser")
    movies = doc.find_all("div", class_="lister-item mode-detail")
    for i in range(len(movies)):
        name.append(movies[i].find("div", class_="lister-item-content").find("a").text)
        genre.append(movies[i].find("div", class_="lister-item-content").find("span", class_="genre").text.replace("\n", "").replace(" ", ""))
        gross.append(movies[i].find("div", class_="list-description").find("b").text)
        rating.append(movies[i].find("span", class_="ipl-rating-star__rating").text)
        runtime.append(movies[i].find("span", class_="runtime").text.replace("min", ""))
        year.append(movies[i].find("span", class_="lister-item-year text-muted unbold").text.replace("(", "").replace(")", "").replace("I", "").replace("II", "").replace("X", "").replace("V", ""))
# #writing the data to .txt
with open("q1text.txt", "w") as data:
    for i in range(1000):
        data.write(name[i] + "--" + genre[i] + "--" + gross[i] + "--")
        data.write(rating[i])
        data.write("--")
        data.write(runtime[i])
        data.write("--")
        data.write(year[i])
        data.write("\n")
genres_count = {}
with open("q1text.txt", "r") as data:
    for line in data:
        genres = line.split("--")[1].split(",")
        for g in genres:
            if g in genres_count:
                genres_count[g] +=1
            else:
                genres_count[g] = 1

df = pd.DataFrame.from_dict(genres_count, orient="index", columns=["Frequency"])
plt.figure(figsize=(10,10))
p = sns.barplot(x = df.index, y = "Frequency", data = df, edgecolor="0.3", linewidth = 1.5)
p.set_title("Genre vs Frequency graph of Top 1000 Highest-Grossing Movies ", fontsize = 17, weight = "bold")
p.set_xlabel("Genre", fontsize=17, weight="bold")
p.set_ylabel("Frequency", fontsize=17, weight="bold")
p.set_xticklabels(p.get_xticklabels(), rotation=40, ha='center')
p.figure.savefig("graph1.png")

gross_graph = {}
with open("q1text.txt", "r") as data2:
    for i, line in enumerate(data2):
        if i>=100:
            break
        name = line.split("--")[0]
        gross_value = line.split("--")[2].replace("\n", "")
        if name in gross_graph:
            name = name + "1994"
        gross_graph[name] = gross_value

df2 = pd.DataFrame.from_dict(gross_graph, orient="index", columns=["Gross"])
plt.figure(figsize=(32,32))
p2 = sns.lineplot(x = df2.index, y="Gross", data = df2)
p2.set_title("Top 100 Movies and their Gross Value", fontsize=17, weight="bold")
plt.xticks(list(gross_graph.keys()), rotation=90, ha='center')
p2.set_ylabel("Gross(in $)", fontsize=17, weight="bold")
p2.figure.savefig("graph2.png")
