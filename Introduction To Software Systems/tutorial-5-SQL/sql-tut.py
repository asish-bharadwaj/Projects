#!/usr/bin/python3
import sqlite3

connection = sqlite3.connect("ipl.db")
cursor = connection.cursor()

#Printing 10 Umpire names using LIMIT clause
umpire_names = "SELECT Umpire_Name FROM Umpire LIMIT 10"
print("Umpire names: ", end = "")
umpires = cursor.execute(umpire_names)
i = 0
for umpire in umpires:
    if i == 9:
        print(umpire[0])
    else:
        print(umpire[0], end=", ")
    i += 1

#Finding the number of unique countries that the umpires belong to
umpire_countries = "SELECT DISTINCT(Umpire_Country) FROM Umpire"
umpires = cursor.execute(umpire_countries)
count = 0
for i in umpires:
    count += 1
print(f"The number of countries the umpires belong to are: {count}")

#Printing venue names in ascending order
venue_names = "SELECT Venue_Name FROM Venue ORDER BY Venue_Name ASC"
venues = cursor.execute(venue_names)
print("Venue names: ", end = "")
for venue in venues:
    if venue[0] == "Wankhede Stadium":
        print(venue[0])
    else:
        print(venue[0], end = ", ")

#Printing the names of all the Australian players in the database
players = cursor.execute("SELECT Player_Name, Country_Name FROM Player WHERE Country_Name == 5 ")
print("Australian players: ", end = "")
for player in players:
    if player[0] == "SM Boland":
        print(player[0])
    else:
        print(player[0], end = ", ")

#Printng number of matches CSK(3) won more than RCB(2)
CSK = cursor.execute("SELECT COUNT(Match_Winner) FROM Match WHERE Match_Winner == 3")
for i in CSK:
    CSKW = i[0]
RCB = cursor.execute("SELECT COUNT(Match_Winner) FROM Match WHERE Match_Winner == 2")
for i in RCB:
    RCBW = i[0]
print(f"The number of matches CSK won more than RCB: {CSKW-RCBW}")