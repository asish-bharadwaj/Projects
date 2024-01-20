DROP DATABASE IF EXISTS `IPL`;
CREATE SCHEMA `IPL`;
USE `IPL`;


DROP TABLE IF EXISTS `SEASON`;
CREATE TABLE `SEASON` (
  `Season_Year` VARCHAR(4) NOT NULL CHECK(`Season_Year` > 2007 AND `Season_Year` < 2025),
  `Champions_Team_ID` INT NOT NULL CHECK(`Champions_Team_ID` > 0 AND `Champions_Team_ID` < 11),
  `Runner_Up_Team_ID` INT NOT NULL CHECK(`Runner_Up_Team_ID` > 0 AND `Runner_Up_Team_ID` < 11),
  `Emerging_Player_ID` INT CHECK(`Emerging_Player_ID` > 0),
  `MVP_Player_ID` INT CHECK(`MVP_Player_ID` > 0),
  `MOTS_Player_ID` INT CHECK(`MOTS_Player_ID` > 0),
  `Orange_Cap_Player_ID` INT CHECK(`Orange_Cap_Player_ID` > 0),
  `Purple_Cap_Player_ID`  INT CHECK(`Purple_Cap_Player_ID` > 0),
  CONSTRAINT SEASONPK
    PRIMARY KEY(`Season_Year`)
);

INSERT INTO `SEASON` (
	`Season_Year`,
    `Champions_Team_ID`,
    `Runner_Up_Team_ID`,
    `Emerging_Player_ID`,
    `MVP_Player_ID`,
    `MOTS_Player_ID`,
    `Orange_Cap_Player_ID`,
    `Purple_Cap_Player_ID`
) VALUES
	('2023', 1, 2, 1, 4, 1, 2, 3),
    ('2022', 2, 1, 9, 10, 11, 12, 2),
    ('2021', 3, 5, 5, 2, 4, 5, 1),
    ('2020', 4, 1, 2, 3, 4, 5, 1),
    ('2019', 1, 5, 2, 3, 4, 5, 1)
;

SELECT * FROM `SEASON`;

DROP TABLE IF EXISTS `BROADCASTERS`; 
CREATE TABLE `BROADCASTERS` (
  `Broadcaster_ID` INT NOT NULL CHECK(`Broadcaster_ID` > 0),
  `Season_Year` VARCHAR(4),
  `Broadcaster_Name` VARCHAR(25) NOT NULL,
  `Contract_ID` INT CHECK(`Contract_ID` > 0) UNIQUE,
  `Bid_Amount` INT CHECK(`Bid_Amount` > 0),
  CONSTRAINT BROADCASTERSPK
    PRIMARY KEY(`Broadcaster_ID`, `Season_Year`),
  CONSTRAINT BROADCASTERSFK
    FOREIGN KEY (`Season_Year`) REFERENCES `SEASON`(`Season_Year`)
);

INSERT INTO `BROADCASTERS`
VALUES
	(1, '2023', 'Star Sports', 1, 120000000),
    (1, '2022', 'Star Sports', 2, 110000000),
    (1, '2021', 'Star Sports', 3, 100000000),
    (1, '2020', 'Star Sports', 4, 90000000),
    (1, '2019', 'Star Sports', 5, 80000000);
    

DROP TABLE IF EXISTS `SPONSERS`; 
CREATE TABLE `SPONSORS` (
  `Sponsor_ID` INT NOT NULL,
  `Season_Year` VARCHAR(4),
  `Sponsor_Name` VARCHAR(25) NOT NULL,
  `Contract_ID` INT UNIQUE,
  `Bid_Amount` INT CHECK(`Bid_Amount` > 0),
  CONSTRAINT SPONSORSPK
    PRIMARY KEY(`Sponsor_ID`, `Season_Year`),
  CONSTRAINT SPONSORSFK
    FOREIGN KEY (`Season_Year`) REFERENCES `SEASON`(`Season_Year`)
);

INSERT INTO `SPONSORS`
VALUES
	(1, '2023', 'Tata', 1, 120000000),
    (2, '2023', 'Dream11', 2, 100000000),
    (3, '2023', 'Signature', 3, 90000000),
    (4, '2023', 'Kamla_Pasad', 4, 80000000),
    (5, '2023', 'Royal Stag', 5, 70000000);

DROP TABLE IF EXISTS `MATCH`; 
CREATE TABLE `MATCH` (
  `Match_ID` INT NOT NULL CHECK(`Match_ID` > 0),
  `Season_Year` VARCHAR(4),
  `Team1_ID` INT NOT NULL CHECK(`Team1_ID` > 0 AND `Team1_ID` < 11),
  `Team2_ID` INT NOT NULL CHECK(`Team2_ID` > 0 AND `Team2_ID` < 11),
  `Match_Date` DATE NOT NULL,
  `Match_Session` TIME NOT NULL,
  `POTM_Player_ID` INT CHECK(`POTM_Player_ID` > 0),
  `Result` VARCHAR(25) NOT NULL,
  `Winning_Team_ID` INT NOT NULL CHECK(`Winning_Team_ID` > 0),
  `Win_Type` VARCHAR(10) NOT NULL,
  `Win_Margin` INT NOT NULL CHECK(`Win_Margin` > 0),
  `UMPIRE_ID` INT NOT NULL CHECK(`UMPIRE_ID` > 0),
  CONSTRAINT MATCHPK
    PRIMARY KEY(`Match_ID`, `Season_Year`),
  CONSTRAINT MATCHFK
    FOREIGN KEY (`Season_Year`) REFERENCES `SEASON`(`Season_Year`)
);

INSERT INTO `MATCH`
VALUES
	(1, '2023', 1, 2, '2023-04-15', '20:00:00', 1, '1 Won', 1, 'Runs', 50, 1),
    (2, '2023', 3, 4, '2023-04-16', '20:00:00', 5, '4 Won', 4, 'Runs', 10, 2),
    (3, '2023', 5, 7, '2023-04-17', '20:00:00', 9, '5 Won', 5, 'Wickets', 5, 1),
    (4, '2023', 6, 10, '2023-04-18', '20:00:00', 20, '10 Won', 10, 'Wickets', 1, 1),
    (5, '2023', 8, 9, '2023-04-19', '20:00:00', 15, '8 Won', 8, 'Runs', 19, 2)
;

DROP TABLE IF EXISTS `TEAM`; 
CREATE TABLE `TEAM` (
  `Team_ID` INT NOT NULL CHECK(`Team_ID` > 0 AND `Team_ID` < 11),
  `Season_Year` VARCHAR(4),
  `Team_Name` VARCHAR(50) NOT NULL,
  `Owner_Name` VARCHAR(25) NOT NULL,
  `Captain_Player_ID` INT NOT NULL CHECK(`Captain_Player_ID` > 0),
  `Vice_Captain_Player_ID` INT NOT NULL CHECK(`Vice_Captain_Player_ID` > 0),
  `Home_Ground_ID` INT NOT NULL CHECK(`Home_Ground_ID` > 0),
  CONSTRAINT TEAMPK
    PRIMARY KEY(`Team_ID`, `Season_Year`),
  CONSTRAINT TEAMFK
    FOREIGN KEY (`Season_Year`) REFERENCES `SEASON`(`Season_Year`)
);

SET GLOBAL FOREIGN_KEY_CHECKS=1;

INSERT INTO `TEAM` (
	`Team_ID`,
	`Season_Year`,
	`Team_Name`,
	`Owner_Name`,
	`Captain_Player_ID`,
	`Vice_Captain_Player_ID`,
	`Home_Ground_ID`
) VALUES
	(1, '2023', 'Gujarat Titans', 'GTOwner', 1, 2, 1),
    (2, '2023', 'Chennai Super Kings', 'CSKOwner', 3, 4, 2),
    (3, '2023', 'Lucknow Super Gaints', 'LSGOwner', 5, 6, 3),
    (4, '2023', 'Mumbai Indians', 'MIOwner', 7, 8, 4),
    (5, '2023', 'Rajasthan Royals', 'RROwner', 9, 10, 5),
    (6, '2023', 'Royal Challengers Banglore', 'RCBOwner', 11, 12, 6),
    (7, '2023', 'Kolkata Knight Riders', 'KKROwner', 13, 14, 7),
    (8, '2023', 'Punjab Kings', 'PBKSOwner', 15, 16, 8),
    (9, '2023', 'Delhi Capitals', 'DCOwner', 17, 18, 9),
    (10, '2023', 'Surisers Hyderabad', 'SRHOwner', 19, 20, 10)
;

INSERT INTO `TEAM` (
	`Team_ID`,
	`Season_Year`,
	`Team_Name`,
	`Owner_Name`,
	`Captain_Player_ID`,
	`Vice_Captain_Player_ID`,
	`Home_Ground_ID`
) VALUES
	(1, '2022', 'Gujarat Titans', 'GTOwner', 1, 2, 1),
    (2, '2022', 'Chennai Super Kings', 'CSKOwner', 3, 4, 2),
    (3, '2022', 'Lucknow Super Gaints', 'LSGOwner', 5, 6, 3),
    (4, '2022', 'Mumbai Indians', 'MIOwner', 7, 8, 4),
    (5, '2022', 'Rajasthan Royals', 'RROwner', 9, 10, 5),
    (6, '2022', 'Royal Challengers Banglore', 'RCBOwner', 11, 12, 6),
    (7, '2022', 'Kolkata Knight Riders', 'KKROwner', 13, 14, 7),
    (8, '2022', 'Punjab Kings', 'PBKSOwner', 15, 16, 8),
    (9, '2022', 'Delhi Capitals', 'DCOwner', 17, 18, 9)
    (1, '2021', 'Gujarat Titans', 'GTOwner', 1, 2, 1),
    (2, '2021', 'Chennai Super Kings', 'CSKOwner', 3, 4, 2),
    (3, '2021', 'Lucknow Super Gaints', 'LSGOwner', 5, 6, 3),
    (4, '2021', 'Mumbai Indians', 'MIOwner', 7, 8, 4),
    (5, '2021', 'Rajasthan Royals', 'RROwner', 9, 10, 5),
    (6, '2021', 'Royal Challengers Banglore', 'RCBOwner', 11, 12, 6),
    (7, '2021', 'Kolkata Knight Riders', 'KKROwner', 13, 14, 7),
    (8, '2021', 'Punjab Kings', 'PBKSOwner', 15, 16, 8),
    (9, '2021', 'Delhi Capitals', 'DCOwner', 17, 18, 9),
    (10, '2021', 'Surisers Hyderabad', 'SRHOwner', 19, 20, 10),
    (1, '2020', 'Gujarat Titans', 'GTOwner', 1, 2, 1),
    (2, '2020', 'Chennai Super Kings', 'CSKOwner', 3, 4, 2),
    (3, '2020', 'Lucknow Super Gaints', 'LSGOwner', 5, 6, 3),
    (4, '2020', 'Mumbai Indians', 'MIOwner', 7, 8, 4),
    (5, '2020', 'Rajasthan Royals', 'RROwner', 9, 10, 5),
    (6, '2020', 'Royal Challengers Banglore', 'RCBOwner', 11, 12, 6),
    (7, '2020', 'Kolkata Knight Riders', 'KKROwner', 13, 14, 7),
    (8, '2020', 'Punjab Kings', 'PBKSOwner', 15, 16, 8),
    (9, '2020', 'Delhi Capitals', 'DCOwner', 17, 18, 9),
    (10, '2020', 'Surisers Hyderabad', 'SRHOwner', 19, 20, 10),
    (1, '2019', 'Gujarat Titans', 'GTOwner', 1, 2, 1),
    (2, '2019', 'Chennai Super Kings', 'CSKOwner', 3, 4, 2),
    (3, '2019', 'Lucknow Super Gaints', 'LSGOwner', 5, 6, 3),
    (4, '2019', 'Mumbai Indians', 'MIOwner', 7, 8, 4),
    (5, '2019', 'Rajasthan Royals', 'RROwner', 9, 10, 5),
    (6, '2019', 'Royal Challengers Banglore', 'RCBOwner', 11, 12, 6),
    (7, '2019', 'Kolkata Knight Riders', 'KKROwner', 13, 14, 7),
    (8, '2019', 'Punjab Kings', 'PBKSOwner', 15, 16, 8),
    (9, '2019', 'Delhi Capitals', 'DCOwner', 17, 18, 9),
    (10, '2019', 'Surisers Hyderabad', 'SRHOwner', 19, 20, 10)
;

SELECT * FROM `TEAM`;

DROP TABLE IF EXISTS `PLAYER`; 
CREATE TABLE `PLAYER` (
  `Player_ID` INT NOT NULL CHECK (`Player_ID` > 0),
  `Team_ID` INT,
  `Season_Year` VARCHAR(4),
  `First_Name` VARCHAR(25) NOT NULL,
  `Last_Name` VARCHAR(25) NOT NULL,
  `Date_of_Birth` DATE,
  `Innings_Batted` INT,
  -- Derived attribute: Age
  `Age` INT GENERATED ALWAYS AS (2023-12-03 - YEAR(`Date_of_Birth`)) STORED CHECK (`Age` > 0),
  `Runs_Scored` INT CHECK(`Runs_Scored` > -1),
  `Runs_Given` INT CHECK(`Runs_Given` > -1),
  `Balls_Faced` INT CHECK(`Balls_Faced` > -1),
  `Balls_Bowled` INT CHECK(`Balls_Bowled` > -1),
  `Wickets` INT CHECK(`Wickets` > -1),
  `Batting_Hand` VARCHAR(10),
  `Bowling_Hand` VARCHAR(10),
  `Highest_Score` INT CHECK(`Highest_Score` > 0),
  -- Derived
  `Average` DOUBLE GENERATED ALWAYS AS (CASE WHEN `Runs_Scored` > 0 THEN `Runs_Scored`/`Innings_Batted` ELSE 0 END) STORED CHECK(`Average` >= 0),
  -- Derived
  `Strike_Rate` DOUBLE GENERATED ALWAYS AS (CASE WHEN `Runs_Scored` > 0 THEN (`Runs_Scored` / `Balls_Faced`) * 100 ELSE 0 END) STORED CHECK(`Strike_Rate` >= 0),
  `100s` INT CHECK(`100s` >= 0),
  `50s` INT CHECK(`50s` >= 0),
  `4s` INT CHECK(`4s` >= 0),
  `6s` INT CHECK(`6s` >= 0),
  -- Derived from balls
  `Overs_Bowled` INT GENERATED ALWAYS AS (CASE WHEN `Balls_Bowled` > 0 THEN (`Balls_Bowled` / 6) ELSE 0 END) STORED CHECK(`Overs_Bowled` >= 0),
  `Best_Bowled_Innings` VARCHAR(10),
  -- Derived
  `Economy` DOUBLE GENERATED ALWAYS AS (CASE WHEN `Overs_Bowled` > 0 THEN (`Runs_Given` / `Overs_Bowled`) ELSE 0 END) STORED,
  `5W` INT CHECK(`5W` >= 0),
  `Country` VARCHAR(25) NOT NULL,
  CONSTRAINT PLAYERPK
    PRIMARY KEY(`Player_ID`, `Team_ID`, `Season_Year`),
  CONSTRAINT PLAYERFKTEAM
    FOREIGN KEY (`Team_ID`) REFERENCES `TEAM`(`Team_ID`),
  CONSTRAINT PLAYERFKSEASON
    FOREIGN KEY (`Season_Year`) REFERENCES `SEASON`(`Season_Year`)
);

INSERT INTO `PLAYER` (
	`Player_ID`,
	`Team_ID`,
	`Season_Year`,
	`First_Name`,
	`Last_Name`,
    `Balls_Faced`,
    `Balls_Bowled`,
	`Date_of_Birth`,
    `Innings_Batted`,
	`Runs_Scored`,
	`Wickets`,
	`Batting_Hand`,
	`Runs_Given`,
	`Bowling_Hand`,
	`Highest_Score`,
	`100s`,
	`50s`,
	`4s`,
	`6s`,
	`Best_Bowled_Innings`,
	`5W`,
	`Country`
) VALUES
	(1, 1, '2023', 'Hardik', 'Pandya', 1583, 1202, '1993-10-11', 115, 2309, 53, 'Right', 1763, 'Right', 91, 0, 0, 172, 125, 1, 0, 'India'),-- 
    (2, 1, '2023', 'Mohammed', 'Shami', 500, 1500, '1990-09-03', 25, 74, 127, 'Right', 2000, 'Right', 21, 0, 0, 6, 2, 2, 0, 'India'),
    (3, 2, '2023', 'Mahedra Singh', 'Dhoni', 7000, 0, '1981-07-07', 218, 5082, 0, 'Right', 0, 'Right', 84, 0, 24, 349, 239, 3, 0, 'India'),
    (4, 2, '2023', 'Deepak', 'Chahar', 200, 1000, '1992-08-07', 13, 80, 72, 'Right', 1200, 'Right', 39, 0, 0, 2, 6, 4, 0, 'India'),
    (5, 3, '2023', 'Lokesh', 'Rahul', 4000, 0, '1992-04-18', 109, 4138, 0, 'Right', 0 ,'Right', 132, 4, 33, 355, 168, 5, 0, 'India'),
    (6, 3, '2023', 'Mark', 'Wood', 20, 100, '1990-01-11', 3, 12, 11, 'Right', 200,'Right', 10, 0, 0, 1, 1, 6, 0, 'England'),
    (7, 4, '2023', 'Rohit', 'Sharma', 5000, 10, '1987-04-30', 238, 6211, 15, 'Right', 30, 'Right', 109, 1, 42, 554, 257, 7, 0, 'India'),
    (8, 4, '2023', 'Jasprit', 'Bumrah', 500, 1200, '1990-09-03', 25, 74, 127, 'Right', 1700, 'Right', 21, 0, 0, 6, 2, 8, 0, 'India'),
    (9, 5, '2023', 'Sanju', 'Samson', 2000, 0, '1981-07-07', 218, 5082, 0, 'Right', 0 ,'Right', 84, 0, 24, 349, 239, 9, 0, 'India'),
    (10, 5, '2023', 'Adam', 'Zampa', 200, 600, '1992-08-07', 13, 80, 72, 'Right', 700 ,'Right', 39, 0, 0, 2, 6, 10, 0, 'Australia'),
    (11, 6, '2023', 'Virat', 'Kohli', 5528, 100, '1998-11-05', 229, 7263, 4, 'Right', 50,'Right', 113, 7, 50, 643, 234, 11, 0, 'India'),
    (12, 6, '2023', 'Mohammed', 'Siraj', 100, 1200, '1990-01-11', 3, 12, 11, 'Right', 1500, 'Right', 10, 0, 0, 1, 1, 6, 2, 'England'),
    (13, 7, '2023', 'Rinku', 'Singh', 500, 0, '1987-04-30', 238, 6211, 15, 'Left', 0,'Left', 109, 1, 42, 554, 257, 7, 0, 'India'),
    (14, 7, '2023', 'Lockie', 'Ferguson', 50, 400, '1992-08-07', 13, 80, 72, 'Right', 500, 'Right', 39, 0, 0, 2, 6, 10, 0, 'New Zealand'),
    (15, 8, '2023', 'Shikar', 'Dhawan', 3000, 0, '1998-11-05', 229, 7263, 4, 'Left', 0,'Left', 113, 7, 50, 643, 234, 11, 0, 'India'),
    (16, 8, '2023', 'Kagiso', 'Rabada', 100, 800, '1992-08-07', 13, 80, 72, 'Right', 1400, 'Right', 39, 0, 0, 2, 6, 10, 0, 'South Africa'),
    (17, 9, '2023', 'David', 'Warner', 4000, 0, '1998-11-05', 200, 6263, 4, 'Left', 0,'Left', 113, 7, 50, 643, 234, 11, 0, 'Australia'),
    (18, 9, '2023', 'Kuldeep', 'Yadav', 100, 1000, '1992-08-07', 13, 80, 72, 'Right', 1200,'Right', 39, 0, 0, 2, 6, 10, 0, 'India'),
    (19, 10, '2023', 'Aiden', 'Markram', 500, 50, '1998-11-05', 229, 7263, 4, 'Right', 100,'Right', 113, 7, 50, 643, 234, 11, 0, 'South Africa'),
    (20, 10, '2023', 'Bhuvneshwar', 'Kumar', 100, 700, '1992-08-07', 13, 80, 72, 'Right', 1000, 'Right', 39, 0, 0, 2, 6, 10, 0, 'India')
;

SELECT * FROM `PLAYER`;

DROP TABLE IF EXISTS `STAFF`; 
CREATE TABLE `STAFF` (
  `Team_ID` INT NOT NULL,
  `First_Name` VARCHAR(25) NOT NULL,
  `Last_Name` VARCHAR(25) NOT NULL,
  `Staff_Role` VARCHAR(25) NOT NULL,
  CONSTRAINT STAFFPK
    PRIMARY KEY (`Team_ID`, `Staff_Role`),
  CONSTRAINT STAFFFK
    FOREIGN KEY (`Team_ID`) REFERENCES `TEAM`(`Team_ID`)
);

INSERT INTO `STAFF`
VALUES
	(4, 'Sachin', 'Tendulkar', 'Mentor'),
    (10, 'VVS', 'Laxman', 'Mentor'),
    (2, 'Stephen', 'Flemming', 'Coach'),
    (6, 'Mike', 'Hesson', 'Coach'),
    (10, 'Tom', 'Moody', 'Coach')
;

DROP TABLE IF EXISTS `UMPIRE`; 
CREATE TABLE `UMPIRE` (
  `Umpire_ID` INT NOT NULL CHECK(`Umpire_ID` > 0),
  `Match_ID` INT NOT NULL,
  `First_Name` VARCHAR(25) NOT NULL,
  `Last_Name` VARCHAR(25) NOT NULL,
  `Country` VARCHAR(25) NOT NULL,
  `Experience` INT CHECK(`Experience` >= 0),
  CONSTRAINT UMPIREPK
    PRIMARY KEY (`Umpire_ID`, `Match_ID`),
  CONSTRAINT UMPIREFK
    FOREIGN KEY (`Match_ID`) REFERENCES `MATCH`(`Match_ID`)
);

INSERT INTO `UMPIRE`
VALUES
	(1, 1, 'Nitin', 'Menon', 'India', 5),
    (1, 3, 'Nitin', 'Menon', 'India', 5),
    (1, 4, 'Nitin', 'Menon', 'India', 5),
    (2, 2, 'Richard', 'Kettlebrough', 'England', 10),
    (2, 5, 'Richard', 'Kettlebrough', 'England', 10)
;

DROP TABLE IF EXISTS `TOSS`; 
CREATE TABLE `TOSS` (
  `Match_ID` INT NOT NULL,
  `Team_ID` INT NOT NULL CHECK(`Team_ID` > 0 AND `Team_ID` < 11),
  `Toss_Decision` VARCHAR(10) NOT NULL,
  `Toss_Outcome` VARCHAR(10) NOT NULL,
  CONSTRAINT TOSSPK
    PRIMARY KEY(`Match_ID`),
  CONSTRAINT TOSSFK
    FOREIGN KEY (`Match_ID`) REFERENCES `MATCH`(`Match_ID`)
);

INSERT INTO `TOSS`
VALUES
	(1, 1, 'Heads', 'Heads'),
    (2, 4, 'Tails', 'Tails'),
    (3, 5, 'Heads', 'Tails'),
    (4, 10, 'Tails', 'Heads'),
    (5, 8, 'Tails', 'Tails')
;



DROP TABLE IF EXISTS `VENUE`; 
CREATE TABLE `VENUE` (
  `Venue_ID` INT NOT NULL CHECK(`Venue_ID` > 0),
  `Season_Year` VARCHAR(4),
  `Venue_Name` VARCHAR(100) NOT NULL,
  `City` VARCHAR(25) NOT NULL,
  `Capacity` INT NOT NULL CHECK(`Capacity` > 0),
  `Country` VARCHAR(25) NOT NULL,
  CONSTRAINT VENUEPK
    PRIMARY KEY(`Venue_ID`, `Season_Year`),
  CONSTRAINT VENUEFK
    FOREIGN KEY (`Season_Year`) REFERENCES `SEASON`(`Season_Year`)
);

INSERT INTO `VENUE`
VALUES
	(1, '2023', 'Narendra Modi Stadium', 'Ahmedabad', 132000, 'India'),
    (2, '2023', 'M A Chidambaram Stadium', 'Chennai', 50000, 'India'),
    (3, '2023', 'BRSABV Ekana Cricket Stadium', 'Lucknow', 50000, 'India'),
    (4, '2023', 'Wankhede Stadium', 'Mumbai', 50000, 'India'),
    (5, '2023', 'Sawai Mansingh Stadium', 'Jaipur', 30000, 'India'),
    (6, '2023', 'M Chinnaswamy Stadium', 'Banglore', 40000, 'India'),
    (7, '2023', 'Eden Gardens', 'Kolkata', 68000, 'India'),
    (8, '2023', 'Inderjit Singh Bindra Stadium', 'Mohali', 27000, 'India'),
    (9, '2023', 'Arun Jaitley Stadium', 'Delhi', 41000, 'India'),
    (10, '2023', 'Rajiv Gandhi International Stadium', 'Hyderabad', 55000, 'India');

DROP TABLE IF EXISTS `BATSMAN_STATS`; 
CREATE TABLE `BATSMAN_STATS` (
  `Match_ID` INT NOT NULL,
  `Player_ID` INT NOT NULL,
  `Runs_Scored` INT NOT NULL CHECK(`Runs_Scored` >= 0),
  `Balls_Played` INT NOT NULL CHECK(`Balls_Played` >= 0),
  `4s` INT NOT NULL CHECK(`4s` >= 0),
  `6s` INT NOT NULL CHECK(`6s` >= 0),
  CONSTRAINT BATSMAN_STATSPK
    PRIMARY KEY (`Match_ID`, `Player_ID`),
  CONSTRAINT BATSMAN_STATSFKMATCH
    FOREIGN KEY (`Match_ID`) REFERENCES `MATCH`(`Match_ID`),
  CONSTRAINT BATSMAN_STATSFKPLAYER
    FOREIGN KEY (`Player_ID`) REFERENCES `PLAYER`(`Player_ID`)
);

INSERT INTO `BATSMAN_STATS`
VALUES
	(1, 1, 52, 38, 4, 5),
    (1, 3, 102, 54, 10, 2),
    (1, 2, 1, 1, 0, 0),
    (2, 5, 47, 29, 4, 5),
    (2, 7, 67, 45, 4, 4)
;

SELECT * FROM `BATSMAN_STATS`;

DROP TABLE IF EXISTS `BOWLER_STATS`; 
CREATE TABLE `BOWLER_STATS` (
  `Match_ID` INT NOT NULL,
  `Player_ID` INT NOT NULL,
  `Overs` DOUBLE NOT NULL CHECK(`Overs` >= 0.0),
  `Maiden_Overs` INT NOT NULL CHECK(`Maiden_Overs` >= 0),
  `Runs` INT NOT NULL CHECK(`Runs` >= 0),
  `Wickets` INT NOT NULL CHECK(`Wickets` >= 0),
  CONSTRAINT BOWLER_STATSPK
    PRIMARY KEY (`Match_ID`, `Player_ID`),
  CONSTRAINT BOWLER_STATSFKMATCH
    FOREIGN KEY (`Match_ID`) REFERENCES `MATCH`(`Match_ID`),
  CONSTRAINT BOWLER_STATSFKPLAYER
    FOREIGN KEY (`Player_ID`) REFERENCES `PLAYER`(`Player_ID`)
);

INSERT INTO `BOWLER_STATS`
VALUES
	(1, 2, 4, 0, 30, 2),
    (1, 4, 4, 0, 27, 1),
    (2, 6, 3, 0, 32, 3),
    (2, 8, 4, 1, 14, 2),
    (3, 10, 4, 0, 54, 0)
;

DROP TABLE IF EXISTS `HOSTED_AT`; 
CREATE TABLE `HOSTED_AT` (
  `Season_Year` VARCHAR(4) NOT NULL,
  `Match_ID` INT NOT NULL,
  `Venue_ID` INT NOT NULL,
  CONSTRAINT HOSTED_ATPK
    PRIMARY KEY (`Season_Year`, `Venue_ID`, `Match_ID`),
  CONSTRAINT HOSTED_ATFKTOSEASON
    FOREIGN KEY (`Season_Year`) REFERENCES `TEAM`(`Season_Year`),
  CONSTRAINT HOSTED_ATFKTOVENUE
    FOREIGN KEY (`Venue_ID`) REFERENCES `VENUE`(`Venue_ID`),
  CONSTRAINT HOSTED_ATFKTOMATCH
    FOREIGN KEY (`Match_ID`) REFERENCES `MATCH`(`Match_ID`)
);

INSERT INTO `HOSTED_AT`
VALUES
	('2023', 1, 1),
    ('2023', 2, 3),
    ('2023', 3, 5),
    ('2023', 4, 6),
    ('2023', 5, 9)
;

DROP TABLE IF EXISTS `BROUGHT_TO_YOU_BY`; 
CREATE TABLE `BROUGHT_TO_YOU_BY` (
  `Season_Year` VARCHAR(4) NOT NULL,
  CONSTRAINT BROUGHT_TO_YOU_BYPK
    PRIMARY KEY (`Season_Year`),
  CONSTRAINT BROUGHT_TO_YOU_BYFK
    FOREIGN KEY (`Season_Year`) REFERENCES `SEASON`(`Season_Year`)
);

INSERT INTO `BROUGHT_TO_YOU_BY`
VALUES
	('2023'),
    ('2022'),
    ('2021'),
    ('2020'),
    ('2019')
;

DROP TABLE IF EXISTS `Broadcaster_ID`; 
CREATE TABLE `Broadcaster_ID` (
  `Season_Year` VARCHAR(4) NOT NULL,
  `Broadcaster_id` INT NOT NULL,
  CONSTRAINT Broadcaster_idPK
    PRIMARY KEY (`Season_Year`, `Broadcaster_id`),
  CONSTRAINT Broadcaster_idFKBROUGHT
    FOREIGN KEY (`Season_Year`) REFERENCES `BROUGHT_TO_YOU_BY`(`Season_Year`),
  CONSTRAINT Broadcaster_idFKBROAD
    FOREIGN KEY (`Broadcaster_id`) REFERENCES `BROADCASTERS`(`Broadcaster_ID`)
);

INSERT INTO `Broadcaster_ID`
VALUES
	('2023', 1),
    ('2022', 1),
    ('2021', 1),
    ('2020', 1),
    ('2019', 1)
;

DROP TABLE IF EXISTS `Sponsor_ID`; 
CREATE TABLE `Sponsor_ID` (
  `Season_Year` VARCHAR(4) NOT NULL,
  `Sponsor_id` INT NOT NULL,
  CONSTRAINT Sponsor_idPK
    PRIMARY KEY (`Season_Year`, `Sponsor_id`),
  CONSTRAINT Sponsor_idFKBROUGHT
    FOREIGN KEY (`Season_Year`) REFERENCES `BROUGHT_TO_YOU_BY`(`Season_Year`),
  CONSTRAINT Sponsor_idFKSPONSOR
    FOREIGN KEY (`Sponsor_id`) REFERENCES `SPONSORS`(`Sponsor_ID`)
);

INSERT INTO `Sponsor_ID`
VALUES
	('2023', 1),
    ('2023', 2),
    ('2023', 3),
    ('2023', 4),
    ('2023', 5)
;

DROP TABLE IF EXISTS `Player_ID`; 
CREATE TABLE `Player_ID` (
  `Season_Year` VARCHAR(4) NOT NULL,
  `Player_id` INT NOT NULL,
  CONSTRAINT Player_idPK
    PRIMARY KEY (`Season_Year`, `Player_id`),
  CONSTRAINT Player_idFKBROUGHT
    FOREIGN KEY (`Season_Year`) REFERENCES `BROUGHT_TO_YOU_BY`(`Season_Year`),
  CONSTRAINT Player_idFKPLAYER
    FOREIGN KEY (`Player_id`) REFERENCES `PLAYER`(`Player_id`)
);

INSERT INTO `Player_ID`
VALUES
	('2023', 1),
    ('2023', 2),
    ('2023', 3),
    ('2023', 4),
    ('2023', 5)
;

DROP TABLE IF EXISTS `TITLES`; 
CREATE TABLE `TITLES` (
  `Team_ID` INT NOT NULL,
  `Title_s` INT NOT NULL,
  CONSTRAINT TITLESPK
    PRIMARY KEY (`Team_ID`, `Title_s`),
  CONSTRAINT TITLESFK  
    FOREIGN KEY (`Team_ID`) REFERENCES `TEAM`(`Team_ID`)
);

INSERT INTO `TITLES`
VALUES
	(1, 2022),
    (2, 2023),
    (4, 2021),
    (4, 2019),
    (6, 2020)
;

	





