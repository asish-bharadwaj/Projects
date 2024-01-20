import pymysql.cursors
from datetime import datetime

def display(output, header):

    if len(output) == 0:
        print("NULL SET!")
        return

    maxLengths = [0] * len(header)

    for i, col_name in enumerate(header):
        maxLengths[i] = len(col_name)

    for row in output:
        for i, val in enumerate(row):
            maxLengths[i] = max(maxLengths[i], len(str(row[val])))

    print('_' * (sum(maxLengths) + len(header) * 2 + 1))

    print('|', end='')
    for i, col_name in enumerate(header):
        print(col_name + ' ' * (maxLengths[i] - len(col_name) + 1) + '|', end='')
    print()

    print('‾' * (sum(maxLengths) + len(header) * 2 + 1))

    for row in output:
        print('|', end='')
        for i, val in enumerate(row):
            print(str(row[val]) + ' ' * (maxLengths[i] - len(str(row[val])) + 1) + '|', end='')
        print()

    print('‾' * (sum(maxLengths) + len(header) * 2 + 1))


def seasonInsert():
    try:
        seasonDetails = {}
        print("Enter details of the season:")
        seasonDetails["Season_Year"] = input("Season Year: ")
        seasonDetails["Champions_Team_ID"] = int(input("Champions_Team_ID: "))
        seasonDetails["Runner_Up_Team_ID"] = int(input("Runner_Up_Team_ID: "))
        seasonDetails["Emerging_Player_ID"] = int(input("Emerging_Player_ID: "))
        seasonDetails["MVP_Player_ID"] = int(input("MVP_Player_ID: "))
        seasonDetails["MOTS_Player_ID"] = int(input("MOTS_Player_ID: "))
        seasonDetails["Orange_Cap_Player_ID"] = int(input("Orange_Cap_Player_ID: "))
        seasonDetails["Purple_Cap_Player_ID"] = int(input("Purple_Cap_Player_ID: "))

        query = "INSERT INTO SEASON VALUES ('%s', %d, %d, %d, %d, %d, %d, %d);" % (seasonDetails["Season_Year"], seasonDetails["Champions_Team_ID"], seasonDetails["Runner_Up_Team_ID"], seasonDetails["Emerging_Player_ID"], seasonDetails["MVP_Player_ID"], seasonDetails["MOTS_Player_ID"], seasonDetails["Orange_Cap_Player_ID"], seasonDetails["Purple_Cap_Player_ID"])
        print(query)
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def broadcasterInsert():
    try:
        broadcasterDetails = {}
        print("Enter details of the broadcaster:")
        broadcasterDetails["Broadcaster_ID"] = int(input("Broadcaster_ID: "))
        broadcasterDetails["Season_Year"] = input("Season_Year: ")
        broadcasterDetails["Broadcaster_Name"] = input("Broadcaster Name: ")
        broadcasterDetails["Contract_ID"] = int(input("Contract_ID: "))
        broadcasterDetails["Bid_Amount"] = int(input("Bid_Amount: "))
        query = "INSERT INTO BROADCASTERS VALUES (%d, '%s', '%s',%d, %d);" % (broadcasterDetails["Broadcaster_ID"], broadcasterDetails["Season_Year"],broadcasterDetails["Broadcaster_Name"], broadcasterDetails["Contract_ID"], broadcasterDetails["Bid_Amount"]  )
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return


def sponsorInsert():
    try:
        sponsorDetails = {}
        print("Enter details of the sponsor:")
        sponsorDetails["Sponsor_ID"] = int(input("Sponsor_ID: "))
        sponsorDetails["Season_Year"] = input("Season_Year: ")
        sponsorDetails["Sponsor_Name"] = input("Sponsor Name: ")
        sponsorDetails["Contract_ID"] = int(input("Contract_ID: "))
        sponsorDetails["Bid_Amount"] = int(input("Bid_Amount: "))
        query = "INSERT INTO SPONSORS VALUES (%d, '%s', '%s',%d, %d);" % (sponsorDetails["Sponsor_ID"], sponsorDetails["Season_Year"],sponsorDetails["Sponsor_Name"],  sponsorDetails["Contract_ID"], sponsorDetails["Bid_Amount"]  )
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def matchInsert():
    try:
        matchDetails = {}
        print("Enter details of the match:")
        matchDetails["Match_ID"] = int(input("Match_ID: "))
        matchDetails["Season_Year"] = input("Season_Year: ")
        matchDetails["Team1_ID"] = int(input("Team1_ID : "))
        matchDetails["Team2_ID"] = int(input("Team2_ID: "))
        matchDetails["Match_Date"] = input("Match_Date: ")
        matchDetails["Match_Session"] = input("Match_Session: ")
        matchDetails["POTM_Player_ID"] = int(input("POTM_Player_ID: "))
        matchDetails["Result"] = input("Result: ")
        matchDetails["Winning_Team_ID"] = int(input("Winning_Team_ID: "))
        matchDetails["Win_Type"] = input("Win_Type: ")
        matchDetails["Win_Margin"] = int(input("Win_Margin: "))
        matchDetails["UMPIRE_ID"] = int(input("Umpire_ID: "))

        query = "INSERT INTO `MATCH` VALUES (%d, '%s', %d,%d,'%s','%s', %d, '%s', %d, '%s', %d, %d);" % (matchDetails["Match_ID"], matchDetails["Season_Year"],matchDetails["Team1_ID"] , 
                                                                                                       matchDetails["Team2_ID"],  matchDetails["Match_Date"],matchDetails["Match_Session"], 
                                                                                                        matchDetails["POTM_Player_ID"], matchDetails["Result"],matchDetails["Winning_Team_ID"],
                                                                                                            matchDetails["Win_Type"] , matchDetails["Win_Margin"], matchDetails["UMPIRE_ID"]    )
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def teamInsert():
    try:
        teamDetails = {}
        print("Enter details of the team:")
        teamDetails["Team_ID"] = int(input("Team_ID: "))
        teamDetails["Season_Year"] = input("Season_Year: ")
        teamDetails["Team_Name"] = input("Team Name: ")
        teamDetails["Owner_Name"] = input("Owner Name: ")
        teamDetails["Captain_Player_ID"] = int(input("Captain_Player_ID: "))
        teamDetails["Vice_Captain_Player_ID"] = int(input("Vice_Captain_Player_ID: "))
        teamDetails["Home_Ground_ID"] = int(input("Home_Ground_ID: "))
        query = "INSERT INTO TEAM VALUES (%d, '%s', '%s', '%s', %d, %d, %d);" % (teamDetails["Team_ID"], teamDetails["Season_Year"],teamDetails["Team_Name"],
                                                                                   teamDetails["Owner_Name"], teamDetails["Captain_Player_ID"], teamDetails["Vice_Captain_Player_ID"],teamDetails["Home_Ground_ID"]  )
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return


def playerInsert():
    try:
        playerDetails = {}
        print("Enter details of the player:")
        playerDetails["Player_ID"] = int(input("Player_ID: "))
        playerDetails["Team_ID"] = int(input("Team_ID: "))
        playerDetails["Season_Year"] = input("Season Year: ")
        playerDetails["First_Name"] = input("First Name: ")
        playerDetails["Last_Name"] = input("Last Name: ")
        playerDetails["Balls_Faced"] = int(input("Balls Faced: "))
        playerDetails["Balls_Bowled"] = int(input("Balls Bowled: "))
        playerDetails["Date_of_Birth"] = input("Date of Birth: ")
        playerDetails["Innings_Batted"] = int(input("Innings Batted: "))
        playerDetails["Runs_Scored"] = int(input("Runs Scored: "))
        playerDetails["Wickets"] = int(input("Wickets: "))
        playerDetails["Batting_Hand"] = input("Batting Hand: ")
        playerDetails["Runs_Given"] = int(input("Runs Given: "))
        playerDetails["Bowling_Hand"] = input("Bowling Hand: ")
        playerDetails["Highest_Score"] = int(input("Highest Score: "))
        playerDetails["100s"] = int(input("100s: "))
        playerDetails["50s"] = int(input("50s: "))
        playerDetails["4s"] = int(input("4s: "))
        playerDetails["6s"] = int(input("6s: "))
        playerDetails["Best_Bowled_Innings"] = input("Best Bowled Innings: ")
        playerDetails["5W"] = int(input("5W: "))
        playerDetails["Country"] = input("Country: ")
        query = "INSERT INTO PLAYER VALUES (Player_ID = %d, Team_ID = %d, Season_Year = '%s', First_Name = '%s', Last_Name = '%s', Balls_Faced = %d, Balls_Bowled = %d, Date_of_Birth = '%s', Innings_Batted = %d, Runs_Scored = %d, Wickets = %d, Batting_Hand = '%s', Runs_Given = %d, Bowling_Hand = '%s', Highest_Score = %d, 100s = %d, 50s = %d, 4s = %d, 6s = %d, Best_Bowled_Innings = '%s', 5W = %d, Country = '%s');"%(
            playerDetails["Player_ID"], playerDetails["Team_ID"], playerDetails["Season_Year"], playerDetails["First_Name"], playerDetails["Last_Name"],
            playerDetails["Balls_Faced"], playerDetails["Balls_Bowled"], playerDetails["Date_of_Birth"], playerDetails["Innings_Batted"], playerDetails["Runs_Scored"],
            playerDetails["Wickets"], playerDetails["Batting_Hand"],playerDetails["Runs_Given"], playerDetails["Bowling_Hand"], playerDetails["Highest_Score"], playerDetails["100s"], playerDetails["50s"],
            playerDetails["4s"], playerDetails["6s"], playerDetails["Best_Bowled_Innings"], playerDetails["5W"], playerDetails["Country"]
        )
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def staffInsert():
    try:
        staffDetails = {}
        print("Enter details of the staff:")
        staffDetails["Team_ID"] = int(input("Team_ID: "))
        staffDetails["First_Name"] = input("First_Name: ")
        staffDetails["Last_Name"] = input("Last Name: ")
        staffDetails["Staff_Role"] = input("Staff Role:")
        query = "INSERT INTO STAFF VALUES (%d, '%s', '%s', '%s');" % ( staffDetails["Team_ID"], staffDetails["First_Name"], staffDetails["Last_Name"], staffDetails["Staff_Role"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return


def umpireInsert():
    try:
        umpireDetails = {}
        print("Enter details of the umpire:")
        umpireDetails["Umpire_ID"] = int(input("Umpire_ID: "))
        umpireDetails["Match_ID"] = int(input("Match_ID: "))
        umpireDetails["First_Name"] = input("First Name: ")
        umpireDetails["Last_Name"] = input("Last Name: ")
        umpireDetails["Country"] = input("Country: ")
        umpireDetails["Experience"] = int(input("Experience: "))
        query = "INSERT INTO UMPIRE VALUES (%d, %d, '%s', '%s', '%s', %d);" % ( umpireDetails["Umpire_ID"], umpireDetails["Match_ID"], umpireDetails["First_Name"], umpireDetails["Last_Name"], umpireDetails["Country"], umpireDetails["Experience"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def tossInsert():
    try:
        tossDetails = {}
        print("Enter details of the toss:")
        tossDetails["Match_ID"] = int(input("Match_ID: "))
        tossDetails["Team_ID"] = int(input("Team_ID: "))
        tossDetails["Toss_Decision"] = input("Toss Decision: ")
        tossDetails["Toss_Outcome"] = input("Toss Outcome: ")
        query = "INSERT INTO TOSS VALUES (%d, %d, '%s', '%s');" % ( tossDetails["Match_ID"], tossDetails["Team_ID"], tossDetails["Toss_Decision"], tossDetails["Toss_Outcome"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def venueInsert():
    try:
        venueDetails = {}
        print("Enter details of the venue:")
        venueDetails["Venue_ID"] = int(input("Venue_ID: "))
        venueDetails["Season_Year"] = input("Season_Year: ")
        venueDetails["Venue_Name"] = input("Venue Name: ")
        venueDetails["City"] = input("City: ")
        venueDetails["Capacity"] = int(input("Capacity: "))
        venueDetails["Country"] = input("Country: ")
        query = "INSERT INTO VENUE VALUES (%d, '%s','%s', '%s', %d, '%s');" % ( venueDetails["Venue_ID"], venueDetails["Season_Year"], venueDetails["Venue_Name"], venueDetails["City"]
                                                                              , venueDetails["Capacity"], venueDetails["Country"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def batsmanScoreInsert():
    try:
        BSDetails = {}
        print("Enter details of the batsman score:")
        BSDetails["Match_ID"] = int(input("Match_ID: "))
        BSDetails["Player_ID"] = int(input("Player_ID: "))
        BSDetails["Runs_Scored"] = int(input("Runs Scored: "))
        BSDetails["Balls_Played"] = int(input("Balls Played: "))
        BSDetails["4s"] = int(input("4s: "))
        BSDetails["6s"] = int(input("6s: "))
        query = "INSERT INTO BATSMAN_STATS VALUES (%d, %d,%d,%d,%d,%d);" % (BSDetails["Match_ID"], BSDetails["Player_ID"], BSDetails["Runs_Scored"], BSDetails["Balls_Played"], BSDetails["4s"], BSDetails["6s"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def bowlerStatInsert():
    try:
        BSDetails = {}
        print("Enter details of the bowler stats:")
        BSDetails["Match_ID"] = int(input("Match_ID: "))
        BSDetails["Player_ID"] = int(input("Player_ID: "))
        BSDetails["Overs"] = float(input("Overs: "))
        BSDetails["Maiden_Overs"] = int(input("Maiden Overs: "))
        BSDetails["Runs"] = int(input("Runs: "))
        BSDetails["Wickets"] = int(input("Wickets: "))
        query = "INSERT INTO BOWLER_STATS VALUES (%d, %d,%d,%d,%d,%d);" % (BSDetails["Match_ID"], BSDetails["Player_ID"], BSDetails["Overs"], BSDetails["Maiden_Overs"], BSDetails["Runs"], BSDetails["Wickets"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def updateMatch():
    try:
        matchDetails = {}
        print("Enter details of the match:")
        matchDetails["Match_ID"] = int(input("Match_ID: "))
        matchDetails["Season_Year"] = input("Season_Year: ")
        matchDetails["Team1_ID"] = int(input("Team1_ID : "))
        matchDetails["Team2_ID"] = int(input("Team2_ID: "))
        matchDetails["Match_Date"] = input("Match_Date: ")
        matchDetails["Match_Session"] = input("Match_Session: ")
        matchDetails["POTM_Player_ID"] = int(input("POTM_Player_ID: "))
        matchDetails["Result"] = input("Result: ")
        matchDetails["Winning_Team_ID"] = int(input("Winning_Team_ID: "))
        matchDetails["Win_Type"] = input("Win_Type: ")
        matchDetails["Win_Margin"] = int(input("Win_Margin: "))
        matchDetails["UMPIRE_ID"] = int(input("Umpire_ID: "))

        # query = "UPDATE `MATCH` SET Match_ID = %d, Season_Year = '%s', Team1_ID = %d, Team2_ID = %d, Match_Date = '%s', Match_Session = '%s', POTM_Player_ID = %d, Result = '%s', Winning_Team_ID = %d, Win_Type = '%s',Win_Margin = %d, UMPIRE_ID = %d WHERE Match_ID = %d;" % (matchDetails["Match_ID"], matchDetails["Season_Year"],matchDetails["Team1_ID"] , 
        #                                                                                                matchDetails["Team2_ID"],  matchDetails["Match_Date"],matchDetails["Match_Session"], 
        #                                                                                                 matchDetails["POTM_Player_ID"], matchDetails["Result"],matchDetails["Winning_Team_ID"],
        #                                                                                                     matchDetails["Win_Type"] , matchDetails["Win_Margin"], matchDetails["UMPIRE_ID"], matchDetails["Match_ID"]    );
        
        query = "UPDATE `MATCH` SET Match_ID = %d, Season_Year = '%s', Team1_ID = %d, Team2_ID = %d, Match_Date = '%s', Match_Session = '%s', POTM_Player_ID = %d, Result = '%s', Winning_Team_ID = %d, Win_Type = '%s', Win_Margin = %d, UMPIRE_ID = %d WHERE Match_ID = %d;" % (matchDetails["Match_ID"], matchDetails["Season_Year"], matchDetails["Team1_ID"], matchDetails["Team2_ID"], matchDetails["Match_Date"], matchDetails["Match_Session"], matchDetails["POTM_Player_ID"], matchDetails["Result"], matchDetails["Winning_Team_ID"], matchDetails["Win_Type"], matchDetails["Win_Margin"], matchDetails["UMPIRE_ID"], matchDetails["Match_ID"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def updateTeam():
    try:
        teamDetails = {}
        print("Enter details of the team:")
        teamDetails["Team_ID"] = int(input("Team_ID: "))
        teamDetails["Season_Year"] = input("Season_Year: ")
        teamDetails["Team_Name"] = input("Team Name: ")
        teamDetails["Owner_Name"] = input("Owner Name: ")
        teamDetails["Captain_Player_ID"] = int(input("Captain_Player_ID: "))
        teamDetails["Vice_Captain_Player_ID"] = int(input("Vice_Captain_Player_ID: "))
        teamDetails["Home_Ground_ID"] = int(input("Home_Ground_ID: "))
        query = "UPDATE TEAM SET Team_ID = %d, Season_Year = '%s',Team_Name = '%s',Owner_Name = '%s',Captain_Player_ID = %d, Vice_Captain_Player_ID = %d, Home_Ground_ID = %d WHERE Team_ID = %d AND Season_Year = '%s';" % (teamDetails["Team_ID"], teamDetails["Season_Year"],teamDetails["Team_Name"],
                                                                                   teamDetails["Owner_Name"], teamDetails["Captain_Player_ID"], teamDetails["Vice_Captain_Player_ID"],teamDetails["Home_Ground_ID"], teamDetails["Team_ID"], teamDetails["Season_Year"]  )
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def updatePlayer():
    try:
        playerDetails = {}
        print("Enter details of the player:")
        playerDetails["Player_ID"] = int(input("Player_ID: "))
        playerDetails["Team_ID"] = int(input("Team_ID: "))
        playerDetails["Season_Year"] = input("Season Year: ")
        playerDetails["First_Name"] = input("First Name: ")
        playerDetails["Last_Name"] = input("Last Name: ")
        playerDetails["Date_of_Birth"] = input("Date of Birth: ")
        given_date = datetime.strptime(playerDetails["Date_of_Birth"], '%Y-%m-%d')
        current_date = datetime.now()
        difference_in_years = current_date - given_date
        if((current_date.month, current_date.date) < (given_date.month, given_date.day)):
            difference_in_years -= 1
        playerDetails["Age"] = difference_in_years
        
        playerDetails["Runs"] = int(input("Runs: "))
        playerDetails["Balls_Played"] = int(input("Balls Played: "))
        playerDetails["Wickets"] = int(input("Wickets: "))
        playerDetails["Batting_Hand"] = input("Batting Hand: ")
        playerDetails["Bowling_Hand"] = input("Bowling Hand: ")
        playerDetails["Highest_Score"] = int(input("Highest Score: "))
        playerDetails["Average"] = int(input("Average: "))
        playerDetails["Strike_Rate"] = (float(playerDetails["Runs"]))/playerDetails["Balls_Played"]
        playerDetails["100s"] = int(input("100s: "))
        playerDetails["50s"] = int(input("50s: "))
        playerDetails["4s"] = int(input("4s: "))
        playerDetails["6s"] = int(input("6s: "))
        playerDetails["Overs_Bowled"] = int(input("Overs Bowled: "))
        playerDetails["Runs_Given"] = int(input("Runs Given: "))
        playerDetails["Best_Bowled_Innings"] = input("Best Bowled Innings: ")
        playerDetails["Economy"] = playerDetails["Runs_Given"]/float(playerDetails["Overs_Bowled"])
        playerDetails["5W"] = int(input("5W: "))
        playerDetails["Country"] = input("Country: ")
        query = "UPDATE PLAYER SET Player_ID = %d, Team_ID = %d, Season_Year = '%s', First_Name = '%s', Last_Name = '%s', Date_of_Birth = '%s', Age = %d, Runs = %d, Balls_Played = %d, Wickets = %d, Batting_Hand = '%s', Bowling_Hand = '%s',Highest_Score =  %d, Average = %f, Strike_Rate = %f, 100s = %d, 50s = %d, 4s = %d, 6s = %d, Overs_Bowled = %d, Runs_Given = %d, Best_Bowled_Innings = '%s',Economy = %f, 5W = %d, Country = '%s' WHERE Player_ID = %d;" % (playerDetails["Player_ID"], playerDetails["Team_ID"],playerDetails["Season_Year"],
                                                                                 playerDetails["First_Name"], playerDetails["Last_Name"], playerDetails["Date_of_Birth"], 
                                                                                  playerDetails["Age"], playerDetails["Runs"], playerDetails["Balls_Played"], 
                                                                                  playerDetails["Wickets"], playerDetails["Batting_Hand"],  playerDetails["Bowling_Hand"],
                                                                                 playerDetails["Highest_Score"],playerDetails["Average"], playerDetails["Strike_Rate"], 
                                                                                   playerDetails["100s"], playerDetails["50s"], playerDetails["4s"], playerDetails["6s"],
                                                                                 playerDetails["Overs_Bowled"], playerDetails["Runs_Given"], playerDetails["Best_Bowled_Innings"],
                                                                                  playerDetails["Economy"], playerDetails["5W"], playerDetails["Country"] , playerDetails["Player_ID"]                    )
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def updateVenue():
    try:
        venueDetails = {}
        print("Enter details of the venue:")
        venueDetails["Venue_ID"] = int(input("Venue_ID: "))
        venueDetails["Season_Year"] = input("Season_Year: ")
        venueDetails["Venue_Name"] = input("Venue Name: ")
        venueDetails["City"] = input("City: ")
        venueDetails["Capacity"] = int(input("Capacity: "))
        venueDetails["Country"] = input("Country: ")
        query = "UPDATE VENUE SET Venue_ID = %d, Season_Year = '%s',Venue_Name = '%s', City = '%s', Capacity = %d,Country = '%s' WHERE Venue_ID = %d;" % ( venueDetails["Venue_ID"], venueDetails["Season_Year"], venueDetails["Venue_Name"], venueDetails["City"]
                                                                              , venueDetails["Capacity"], venueDetails["Country"], venueDetails["Venue_ID"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def updateBatsmanScore():
    try:
        BSDetails = {}
        print("Enter details of the batsman score:")
        BSDetails["Match_ID"] = int(input("Match_ID: "))
        BSDetails["Player_ID"] = int(input("Player_ID: "))
        BSDetails["Runs_Scored"] = int(input("Runs Scored: "))
        BSDetails["Balls_Played"] = int(input("Balls Played: "))
        BSDetails["4s"] = int(input("4s: "))
        BSDetails["6s"] = int(input("6s: "))
        query = "UPDATE BATSMAN_STATS SET Match_ID = %d, Player_ID = %d,Runs_Scored = %d,Balls_Played = %d,4s = %d,6s = %d WHERE (Match_ID = %d AND Player_ID = %d);" % (BSDetails["Match_ID"], BSDetails["Player_ID"], BSDetails["Runs_Scored"], BSDetails["Balls_Played"], BSDetails["4s"], BSDetails["6s"], BSDetails["Match_ID"], BSDetails["Player_ID"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def updateBowlerStat():
    try:
        BSDetails = {}
        print("Enter details of the bowler stats:")
        BSDetails["Match_ID"] = int(input("Match_ID: "))
        BSDetails["Player_ID"] = int(input("Player_ID: "))
        BSDetails["Overs"] = float(input("Overs: "))
        BSDetails["Maiden_Overs"] = int(input("Maiden Overs: "))
        BSDetails["Runs"] = int(input("Runs: "))
        BSDetails["Wickets"] = int(input("Wickets: "))
        query = "UPDATE BOWLER_STATS SET Match_ID = %d, Player_ID = %d, Overs = %d, Maiden_Overs = %d, Runs = %d, Wickets = %d WHERE (Match_ID = %d AND Player_ID = %d);" % (BSDetails["Match_ID"], BSDetails["Player_ID"], BSDetails["Overs"], BSDetails["Maiden_Overs"], BSDetails["Runs"], BSDetails["Wickets"], BSDetails["Match_ID"], BSDetails["Player_ID"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return


def updateStaff():
    try:
        staffDetails = {}
        print("Enter details of the staff:")
        staffDetails["Team_ID"] = int(input("Team_ID: "))
        staffDetails["First_Name"] = input("First_Name: ")
        staffDetails["Last_Name"] = input("Last Name: ")
        staffDetails["Staff_Role"] = input("Staff Role:")
        query = "UPDATE STAFF SET Team_ID = %d,First_Name = '%s',Last_Name = '%s',Staff_Role = '%s' WHERE (Team_ID = %d AND Staff_Role = '%s');" % ( staffDetails["Team_ID"], staffDetails["First_Name"], staffDetails["Last_Name"], staffDetails["Staff_Role"], staffDetails["Team_ID"], staffDetails["Staff_Role"])
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def deleteTeams():
    try:
        Team_ID = int(input("Enter Team_ID of the team to be deleted: "))
        query = f"DELETE FROM TEAM WHERE Team_ID = {Team_ID};"
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def archivePlayerRecord():
    try:
        Team_ID = int(input("Enter Player_ID of the player to be archived: "))
        query = f"UPDATE PLAYER SET Team_ID = NULL WHERE Team_ID = {Team_ID};"
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def deleteVenue():
    try:
        Venue_ID = int(input("Enter Venue_ID of the venue to be deleted: "))
        query = f"DELETE FROM VENUE WHERE Venue_ID = {Venue_ID};"
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def deleteUmpire():
    try:
        Umpire_ID = int(input("Enter Umpire_ID of the umpire to be deleted: "))
        query = f"DELETE FROM UMPIRE WHERE Umpire_ID = {Umpire_ID};"
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def deleteStaff():
    try:
        Team_ID = int(input("Enter Team_ID of the staff person to be deleted: "))
        Staff_Role = input("Enter Staff_Role of the staff person to be deleted: ")
        query = f"DELETE FROM STAFF WHERE (Team_ID = {Team_ID} AND Staff_Role = '{Staff_Role}');"
        cur.execute(query)
        con.commit()
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def searchChampion():
    try:
        Season_Year = int(input("Enter Season_Year of the season for which Champion data is to be retrieved: "))
        query = f"SELECT * FROM TEAM WHERE (Team_ID, Season_Year) IN (SELECT Champions_Team_ID, Season_Year FROM SEASON WHERE Season_Year = '{Season_Year}');"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        print(output)
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def searchBroadcaster():
    try:
        Broadcaster_name = (input("Enter Broadcaster_Name of the broadcaster for which Broadcaster data is to be retrieved: "))
        Season_Year = int(input("Enter Season_Year of the season for which Broadcaster data is to be retrieved: "))
        query = f"SELECT * FROM BROADCASTERS WHERE (Broadcaster_Name = '{Broadcaster_name}' AND Season_Year = {Season_Year});"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def searchSponsor():
    try:
        Sponsor_name = (input("Enter Sponsor_Name of the sponsor for which Sponsor data is to be retrieved: "))
        # print(Sponsor_name)
        Season_Year = (input("Enter Season_Year of the season for which Sponsor data is to be retrieved: "))
        query = f"SELECT * FROM SPONSORS WHERE (Sponsor_Name = '{Sponsor_name}' AND Season_Year = '{Season_Year}');"
        # print(query)
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def searchMatch():
    try:
        Team_name = input("Enter Team_name of the team for which matches data is to be retrieved: ")
        Season_Year = int(input("Enter Season_Year of the season for which matches data is to be retrieved: "))
        query = f"SELECT `MATCH`.Match_ID, `MATCH`.Season_Year, `MATCH`.Team1_ID, `MATCH`.Team2_ID, `MATCH`.Match_Date, `MATCH`.Match_Session, `MATCH`.POTM_Player_ID, `MATCH`.Result, `MATCH`.Winning_Team_ID, `MATCH`.Win_Type, `MATCH`.Win_Margin, `MATCH`.UMPIRE_ID FROM `MATCH`, TEAM WHERE `MATCH`.Season_Year = {Season_Year} AND ((`MATCH`.Team1_ID = TEAM.Team_ID) OR (`MATCH`.Team2_ID = TEAM.Team_ID)) AND TEAM.Team_Name = '{Team_name}' AND TEAM.Season_Year = {Season_Year};"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def searchVenue():
    try:
        Venue_name = input("Enter Venue_name of the venue for which matches data is to be retrieved: ")
        query = f"SELECT `MATCH`.Match_ID, `MATCH`.Season_Year, `MATCH`.Team1_ID, `MATCH`.Team2_ID, `MATCH`.Match_Date, `MATCH`.Match_Session, `MATCH`.POTM_Player_ID, `MATCH`.Result, `MATCH`.Winning_Team_ID, `MATCH`.Win_Type, `MATCH`.Win_Margin, `MATCH`.UMPIRE_ID FROM `MATCH`, VENUE, HOSTED_AT WHERE `MATCH`.Match_ID = HOSTED_AT.Match_id AND VENUE.Venue_ID = HOSTED_AT.Venue_id AND VENUE.Venue_Name = '{Venue_name}';"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return  

def searchPlayer():
    try:
        print("a. Search for a player record by player's first name and last name")
        print("b. Search for all player names in a team by team name")
        option = input()
        if option == 'a':

            first_name = input("Enter First_name of the player for which data is to be retrieved: ")
            last_name = input("Enter Last_name of the player for which data is to be retrieved: ")
            query = f"SELECT * FROM PLAYER WHERE First_Name = '{first_name}' AND Last_Name = '{last_name}';"
            cur.execute(query)
            con.commit()
            output = cur.fetchall()
            header = [col[0] for col in cur.description]
            display(output, header)
        
        elif option == 'b':
            team_name = input("Enter Team_Name of the Team for which players data is to be retrieved: ")
            query = f"SELECT * FROM PLAYER, TEAM WHERE PLAYER.Team_ID = TEAM.Team_ID AND TEAM.Team_Name = '{team_name}';"
            cur.execute(query)
            con.commit()
            output = cur.fetchall()
            header = [col[0] for col in cur.description]
            display(output, header)
        else:
            print("Invalid option!")
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def searchTeam():
    try:
        team_name = input("Enter Team_Name of the team for which data is to be retrieved: ")
        query = f"SELECT * FROM TEAM WHERE Team_Name = '{team_name}';"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def searchSeason():
    try:
        print("a. Search for season data by Season_Year")
        print("b. Search for season(s) data by Champions_Team_ID")
        option = input()
        if option == 'a':
            season_year = input("Enter Season_Year of the season for which data is to be retrieved: ")
            query = f"SELECT * FROM SEASON WHERE Season_Year = '{season_year}';"
            cur.execute(query)
            con.commit()
            output = cur.fetchall()
            header = [col[0] for col in cur.description]
            display(output, header)
        elif option == 'b':
            champions_team_id = input("Enter Champions_Team_ID of the team from which season's data is to be retrieved: ")
            query = f"SELECT * FROM SEASON WHERE Champions_Team_ID = '{champions_team_id}';"
            cur.execute(query)
            con.commit()
            output = cur.fetchall()
            header = [col[0] for col in cur.description]
            display(output, header)
        else:
            print("Invalid input!")
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def countSponsors():
    try:
        query = "SELECT Season_Year, COUNT(*) AS NUMBER_OF_SPONSORS FROM SPONSORS GROUP BY Season_Year;"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def umpireStats():
    try:
        season_year = input("Enter Season_Year of the season for which data is to be retrieved: ")
        query = f"SELECT UMPIRE.Umpire_ID, ANY_VALUE(UMPIRE.First_Name) AS First_Name, ANY_VALUE(UMPIRE.Last_Name) AS Last_Name, ANY_VALUE(UMPIRE.Country) AS Country, ANY_VALUE(UMPIRE.Experience) AS  Experience, COUNT(*) AS NUMBER_OF_MATCHES FROM UMPIRE, `MATCH` WHERE UMPIRE.Match_ID = `MATCH`.Match_ID AND `MATCH`.Season_Year = {season_year} GROUP BY UMPIRE.Umpire_ID;"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def aggregateVenueData():
    try:
        query = "SELECT ANY_VALUE(Venue_ID) AS Venue_ID, ANY_VALUE(Venue_Name) AS Venue_Name, ANY_VALUE(City) AS City, ANY_VALUE(Capacity) AS Capacity, ANY_VALUE(Country) AS Country, COUNT(*) AS NUMBER_OF_MATCHES FROM VENUE GROUP BY Venue_ID;"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return


def playerRecords():
    try:
        season_year = input("Enter the Season_Year for which the records are to be retrieved:")
        query = "SELECT Player_ID, First_Name, Last_Name, SUM(Runs_Scored) AS TOTAL_RUNS_SCORED, SUM(Wickets) AS TOTAL_WICKETS_TAKEN FROM (BATSMAN_STATS FULL OUTER JOIN BOWLER_STATS ON BATSMAN_STATS.Match_ID = BOWLER_STATS.Match_ID AND BATSMAN_STATS.Player_ID = BOWLER_STATS.Player_ID) INNER JOIN PLAYER ON (PLAYER.Player_ID = BATSMAN_STATS.Player_ID OR PLAYER.Player_ID = BOWLER_STATS.Player_ID) GROUP BY PLAYER.Player_ID;"
        # print(query)
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def matchResultofaTeam():
    try:
        season_year = input("Enter the Season_Year for which the records are to be retrieved:")
        query = f"SELECT ANY_VALUE(TEAM.Team_Name) AS Team_Name, COUNT(*) FROM `MATCH`, TEAM WHERE `MATCH`.Winning_Team_ID = TEAM.Team_ID AND `MATCH`.Season_Year = '{season_year}' AND TEAM.Season_Year = '{season_year}' GROUP BY TEAM.Team_ID;"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def teamStatistics():
    try:
        season_year = input("Enter the Season_Year for which the records are to be retrieved:")
        query = f"SELECT ANY_VALUE(TEAM.Team_ID) AS Team_ID, ANY_VALUE(TEAM.Team_Name) AS Team_Name, SUM(BATSMAN_STATS.Runs_Scored) AS TOTAL_RUNS FROM (BATSMAN_STATS INNER JOIN PLAYER ON PLAYER.Player_ID = BATSMAN_STATS.Player_ID) INNER JOIN TEAM ON TEAM.Team_ID = PLAYER.Team_ID, `MATCH` WHERE `MATCH`.Season_Year = '{season_year}' AND `MATCH`.Match_ID = BATSMAN_STATS.Match_ID AND TEAM.Season_Year = '{season_year}' GROUP BY TEAM.Team_ID;"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def listCurrentTeams():
    try:
        season_year = input("Enter the Season_Year for which the records are to be retrieved:")
        query = f"SELECT * FROM TEAM WHERE Season_Year = '{season_year}';"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def listMatchesbyDate():
    try:
        query = f"SELECT * FROM `MATCH` ORDER BY Match_Date DESC, Match_Session DESC;"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def listMatchResults():
    try:
        query = f"SELECT * FROM `MATCH`;"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def venuesAvailable():
    try:
        query = f"SELECT * FROM VENUE ORDER BY Capacity DESC;"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def pointsTable():
    try:
        season_year = input("Enter the Season_Year for which the records are to be retrieved:")
        query = f"SELECT ANY_VALUE(Team_ID) AS Team_ID, ANY_VALUE(Team_Name) AS Team_name, ANY_VALUE(Owner_Name) AS Owner_Name, ANY_VALUE(Captain_Player_ID) AS Captain_Player_ID, ANY_VALUE(Vice_Captain_Player_ID) AS Vice_Captain_Player_ID, COUNT(*) AS NUMBER_OF_WINS FROM `MATCH` INNER JOIN TEAM ON `MATCH`.Winning_Team_ID = TEAM.Team_ID AND TEAM.Season_Year = '{season_year}' AND `MATCH`.Season_Year = '{season_year}' GROUP BY TEAM.Team_ID ORDER BY NUMBER_OF_WINS DESC;"
        cur.execute(query)
        con.commit()
        output = cur.fetchall()
        header = [col[0] for col in cur.description]
        display(output, header)
    
    except Exception as e:
        con.rollback()
        print("Failed to insert into database")
        print(">>>>>>>>>>>>>", e)

    return

def dispatchAdmin(ch):
    """
    Function that maps helper functions to option entered
    """

    if(ch == 1):
        seasonInsert()
    elif(ch == 2):
        broadcasterInsert()
    elif(ch == 3):
        sponsorInsert()
    elif(ch == 4):
        matchInsert()
    elif(ch == 5):
        teamInsert()
    elif(ch == 6):
        playerInsert()
    elif(ch == 7):
        staffInsert()
    elif(ch == 8):
        umpireInsert()
    elif(ch == 9):
        tossInsert()
    elif(ch == 10):
        venueInsert()
    elif(ch == 11):
        batsmanScoreInsert()
    elif(ch == 12):
        bowlerStatInsert()
    elif(ch == 13):
        updateMatch()
    elif(ch == 14):
        updateTeam()
    elif(ch == 15):
        updatePlayer()
    elif(ch == 16):
        updateVenue()
    elif(ch == 17):
        updateBatsmanScore()
    elif(ch == 18):
        updateBowlerStat()
    elif(ch == 19):
        updateStaff()
    elif(ch == 20):
        deleteTeams()
    elif(ch == 21):
        archivePlayerRecord()
    elif(ch == 22):
        deleteVenue()
    elif(ch == 23):
        deleteUmpire()
    elif(ch == 24):
        deleteStaff()
    elif(ch == 25):
        searchChampion()
    elif(ch == 26):
        searchBroadcaster()
    elif(ch == 27):
        searchSponsor()
    elif(ch == 28):
        searchMatch()
    elif(ch == 29):
        searchVenue()
    elif(ch == 30):
        searchTeam()
    elif(ch == 31):
        searchPlayer()
    elif(ch == 32):
        searchSeason()
    elif(ch == 33):
        countSponsors()
    elif(ch == 34):
        umpireStats()
    elif(ch == 35):
        aggregateVenueData()
    elif(ch == 36):
        matchResultofaTeam()
    elif(ch == 37):
        teamStatistics()
    elif(ch == 38):
        listCurrentTeams()
    elif(ch == 39):
        listMatchesbyDate()
    elif(ch == 40):
        listMatchResults()
    elif(ch == 41):
        venuesAvailable()
    elif(ch == 42):
        pointsTable()

def dispatchUser(ch):
    if(ch == 1):
        searchChampion()
    elif(ch == 2):
        searchBroadcaster()
    elif(ch == 3):
        searchSponsor()
    elif(ch == 4):
        searchMatch()
    elif(ch == 5):
        searchVenue()
    elif(ch == 6):
        searchTeam()
    elif(ch == 7):
        searchPlayer()
    elif(ch == 8):
        searchSeason()
    elif(ch == 9):
        countSponsors()
    elif(ch == 10):
        umpireStats()
    elif(ch == 11):
        aggregateVenueData()
    elif(ch == 12):
        matchResultofaTeam()
    elif(ch == 13):
        teamStatistics()
    elif(ch == 14):
        listCurrentTeams()
    elif(ch == 15):
        listMatchesbyDate()
    elif(ch == 16):
        listMatchResults()
    elif(ch == 17):
        venuesAvailable()
    elif(ch == 18):
        pointsTable()


# Global
while(1):
    username = input("Username: ")
    password = input("Password: ")
    try:
        # Set db name accordingly which have been create by you
        # Set host to the server's address if you don't want to use local SQL server 
        con = pymysql.connect(host='localhost',
                              user="root",
                              password="Aditya@180203",
                              db='IPL',
                              cursorclass=pymysql.cursors.DictCursor)
        if(con.open):
            print("Connected")
        else:
            print("Failed to connect")

        with con.cursor() as cur:
            while(1):
                if username == "admin" and password == "admin":
                    print("1.  Insert Season")
                    print("2.  Insert Broadcaster")
                    print("3.  Insert Sponsor")
                    print("4.  Insert Match")
                    print("5.  Insert Team")
                    print("6.  Insert Player")
                    print("7.  Insert Staff")
                    print("8.  Insert Umpire")
                    print("9.  Insert Toss")
                    print("10. Insert Venue")
                    print("11. Insert Batsman Score")
                    print("12. Insert Bowler Stat")
                    print("13. Updat Match")
                    print("14. Update Team")
                    print("15. Update Player")
                    print("16. Update Venue")
                    print("17. Update Batsman Score")
                    print("18. Update Bowler Stat")
                    print("19. Update Staff")
                    print("20. Delete Team")
                    print("21. Archive Player Records")
                    print("22. Delete Venue")
                    print("23. Delete Umpire")
                    print("24. Delete Staff")
                    print("25. Search Champion")
                    print("26. Search Broadcaster")
                    print("27. Search Sponsor")
                    print("28. Search Match")
                    print("29. Search Venue")
                    print("30. Search Team")
                    print("31. Search Player")
                    print("32. Search Season")
                    print("33. Count Sponsors")
                    print("34. Umpire Stats")
                    print("35. Aggregate Venue Data")
                    print("36. Count Match Results of a Team")
                    print("37. Team Statistics")
                    print("38. List Current Teams")
                    print("39. List Matches By Date")
                    print("40. List Match Results of a Season")
                    print("41. List Venues Available")
                    print("42. Display Points Table")
                    print("-1. Logout")

                    ch = int(input("Enter choice> "))
                    
                    
                    if ch == -1:
                        print("Bye!")
                        exit()
                    else:
                        dispatchAdmin(ch)
                else:
                    print("1. Search Champion")
                    print("2. Search Broadcaster")
                    print("3. Search Sponsor")
                    print("4. Search Match")
                    print("5. Search Venue")
                    print("6. Search Team")
                    print("7. Search Player")
                    print("8. Search Season")
                    print("9. Count Sponsors")
                    print("10. Umpire Stats")
                    print("11. Aggregate Venue Data")
                    print("12. Count Match Results of a Team")
                    print("13. Team Statistics")
                    print("14. List Current Teams")
                    print("15. List Matches By Date")
                    print("16. List Match Results of a Season")
                    print("17. List Venues Available")
                    print("18. Display Points Table")
                    print("-1. Logout")
                    ch = int(input("Enter choice> "))
                    
                    
                    if ch == -1:
                        print("Bye!")
                        exit()
                    else:
                        dispatchUser(ch)
    except Exception as e:
        print(e)
        print("Connection Refused: Either username or password is incorrect or user doesn't have access to database")
         
            

