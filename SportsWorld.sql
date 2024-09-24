-- Changing the path from public schema to sports schema. 
-- The sports schema will contain will the tables.
SET search_path TO sports;

-- Checking if the path is set to sports schema or not
SHOW search_path;

-- Creating a table called leagues
CREATE TABLE leagues (league_id SERIAL PRIMARY KEY, league_name VARCHAR(50), sport_type VARCHAR(20));

-- Creating a table called teams
CREATE TABLE teams (team_id SERIAL PRIMARY KEY, team_name VARCHAR(50), league_id INT REFERENCES leagues(league_id));

-- Creating a table called players
CREATE TABLE players (player_id SERIAL PRIMARY KEY, player_name VARCHAR(50), team_id INT REFERENCES teams(team_id), poisition VARCHAR(50), role VARCHAR(50));

-- Creating a table called matches
CREATE TABLE matches (match_id SERIAL PRIMARY KEY, league_id INT REFERENCES leagues(league_id), team_id1 INT REFERENCES teams(team_id), team_id2 INT REFERENCES teams(team_id), match_date DATE, match_type VARCHAR(20));

-- Creating a table called scores
CREATE TABLE scores (score_id SERIAL PRIMARY KEY, match_id INT REFERENCES matches(match_id), team_id INT REFERENCES teams(team_id), score_type VARCHAR(50), score_value INT);

-- Creating a table called player_statistics
CREATE TABLE player_statistics (player_statistics_id SERIAL PRIMARY KEY, player_id INT REFERENCES players(player_id), match_id INT REFERENCES matches(match_id), score_type VARCHAR(50), score_value INT);

-- Inserting values into the leagues table
INSERT INTO leagues (league_name, sport_type) VALUES
('Premier League', 'Football'),
('La Liga', 'Football'),
('Bundesliga', 'Football'),
('Serie A', 'Football'),
('IPL', 'Cricket'),
('Big Bash', 'Cricket'),
('Caribbean Premier League', 'Cricket'),
('ICC T20 World Cup', 'Cricket'),
('UEFA Champions League', 'Football'),
('FA Cup', 'Football');

-- Displaying the leagues table
SELECT * FROM leagues;

INSERT INTO teams (team_name, league_id) VALUES
('Manchester United', 1),
('Real Madrid', 2),
('Bayern Munich', 3),
('Juventus', 4),
('Mumbai Indians', 5),
('Sydney Sixers', 6),
('Trinbago Knight Riders', 7),
('Australia', 8),
('Liverpool', 1),
('Barcelona', 2);

-- Displaying the teams table
SELECT * FROM teams;

-- Inserting values into the players table
INSERT INTO players (player_name, team_id, poisition, role) VALUES
('Cristiano Ronaldo', 1, 'Forward', NULL),
('Lionel Messi', 2, 'Forward', NULL),
('Robert Lewandowski', 3, 'Forward', NULL),
('Giorgio Chiellini', 4, NULL, 'Bowler'),
('Rohit Sharma', 5, NULL, 'Batsman'),
('Steve Smith', 5, NULL, 'Batsman'),
('Glenn Maxwell', 6, NULL, 'All-Rounder'),
('Andre Russell', 7, NULL, 'All-Rounder'),
('Virat Kohli', 5, NULL, 'Batsman'),
('Mohamed Salah', 9, 'Forward', NULL);

-- Displaying the players table
SELECT * FROM players;

-- Inserting values into the matches table
INSERT INTO matches (league_id, team_id1, team_id2, match_date, match_type) VALUES
(1, 1, 9, '2024-09-20', 'League'),
(2, 2, 1, '2024-09-22', 'League'),
(3, 3, 4, '2024-09-23', 'League'),
(5, 5, 6, '2024-09-24', 'Tournament'),
(7, 7, 8, '2024-09-25', 'Tournament'),
(8, 8, 5, '2024-09-26', 'League'),
(1, 1, 2, '2024-09-27', 'League'),
(3, 4, 2, '2024-09-28', 'Tournament'),
(6, 6, 7, '2024-09-29', 'League'),
(5, 8, 4, '2024-09-30', 'Tournament');

-- Displaying the matches table
SELECT * FROM matches;

-- Inserting values into the scores table
INSERT INTO scores (match_id, team_id, score_type, score_value) VALUES
(1, 1, 'Goals', 2),
(2, 2, 'Goals', 1),
(3, 3, 'Goals', 3),
(4, 5, 'Runs', 180),
(5, 7, 'Runs', 200),
(6, 8, 'Goals', 1),
(7, 1, 'Goals', 3),
(8, 4, 'Runs', 220),
(9, 6, 'Runs', 190),
(10, 5, 'Runs', 210);

-- Displaying the scores table
SELECT * FROM scores;

-- Inserting values into the player_statistics table
INSERT INTO player_statistics (player_id, match_id, score_type, score_value) VALUES
(1, 1, 'Goals', 1),
(2, 2, 'Goals', 1),
(3, 3, 'Goals', 2),
(4, 5, 'Wickets', 3),
(5, 4, 'Runs', 50),
(6, 4, 'Runs', 45),
(7, 6, 'Runs', 30),
(8, 7, 'Runs', 25),
(9, 4, 'Runs', 70),
(10, 1, 'Goals', 1);

-- Displaying the player_statistics table
SELECT * FROM player_statistics;

-- Creating a stored procedure for finding out the Top Scoring Players.
-- The stored procedure takes the following inputs - LeagueID, MatchDate range
-- The stored procedure gives the following outputs - PlayerName, TeamName, ScoreType, TotalScore
-- The stored procedure displays the output in the following sorting order - Highest total score should be on top
CREATE OR REPLACE FUNCTION top_scoring_players(p_league_id INT, match_date_start DATE, match_date_end DATE)
RETURNS TABLE(player_name VARCHAR, team_name VARCHAR, score_type VARCHAR, total_score INT)
LANGUAGE plpgsql
AS
$$
BEGIN
RETURN QUERY
SELECT p.player_name, t.team_name, s.score_type, SUM(s.score_value)::INT AS TotalScore  
FROM players p
INNER JOIN teams t ON p.team_id = t.team_id
INNER JOIN scores s ON s.team_id = t.team_id
INNER JOIN matches m ON m.match_id = s.match_id
WHERE t.league_id = p_league_id AND m.match_date BETWEEN match_date_start AND match_date_end
GROUP BY p.player_name, t.team_name, s.score_type
ORDER BY total_score DESC;
END
$$;

-- Calling the stored procedure top_scoring_players
SELECT * FROM top_scoring_players(1, '2024-09-20', '2024-09-30');

-- Creating a stored procedure for finding out the Team Standings:
-- The stored procedure takes the following inputs - LeagueID, MatchDate range
-- The stored procedure gives the following outputs - TeamName, Wins, Losses, Draws, Points
-- The stored procedure displays the output in the following sorting order - Team with highest points should be on top
CREATE OR REPLACE FUNCTION team_standings(p_league_id INT, match_date_start DATE, match_date_end DATE)
RETURNS TABLE(team_name VARCHAR, wins INT, losses INT, draws INT, points INT)
LANGUAGE plpgsql
AS
$$
BEGIN
RETURN QUERY
SELECT t.team_name, COUNT(CASE WHEN s.score_type = 'Wins' THEN 1 END)::INT AS wins, COUNT(CASE WHEN s.score_type = 'Losses' THEN 1 END)::INT AS losses, COUNT(CASE WHEN s.score_type = 'Draws' THEN 1 END)::INT AS draws, (COUNT(CASE WHEN s.score_type = 'Wins' THEN 1 END) * 3 + COUNT(CASE WHEN s.score_type = 'Draws' THEN 1 END))::INT AS points FROM teams t
LEFT JOIN matches m ON t.team_id IN (m.team_id1, m.team_id2)
LEFT JOIN scores s ON s.match_id = m.match_id AND s.team_id = t.team_id
WHERE t.league_id = p_league_id AND m.match_date BETWEEN match_date_start AND match_date_end
GROUP BY t.team_name
ORDER BY points DESC;
END
$$;

-- Calling the stored procedure team_standings
SELECT * FROM team_standings(1, '2024-09-20', '2024-09-30');

-- Creating a stored procedure for finding out the Match Schedule:
-- The stored procedure takes the following inputs - LeagueID, MatchDate range
-- The stored procedure gives the following outputs - MatchID, TeamName1, TeamName2, MatchDate, MatchType
-- The stored procedure displays the output in the following sorting order - MatchDate and MatchType
CREATE OR REPLACE FUNCTION match_schedule(p_league_id INT, match_date_start DATE, match_date_end DATE)
RETURNS TABLE(match_iD INT, team_name1 VARCHAR, team_name2 VARCHAR, match_date DATE, match_type VARCHAR)
LANGUAGE plpgsql
AS
$$
BEGIN
RETURN QUERY
SELECT m.match_id, t1.team_name AS team_name1, t2.team_name AS team_name2, m.match_date, m.match_type FROM matches m
INNER JOIN teams t1 ON m.team_id1 = t1.team_id
INNER JOIN teams t2 ON m.team_id2 = t2.team_id
WHERE t1.league_id = p_league_id AND m.match_date BETWEEN match_date_start AND match_date_end
ORDER BY m.match_date, m.match_type;
END
$$;

-- Calling the stored procedure match_schedule
SELECT * FROM match_schedule(1, '2024-09-20', '2024-09-30');

-- Creating a stored procedure for finding out the Player Performance:
-- The stored procedure takes the following inputs - PlayerID, MatchDate range
-- The stored procedure gives the following outputs - PlayerName, TeamName, ScoreType, TotalScore
-- The stored procedure displays the output in the following sorting order - Highest total score should be on top
CREATE OR REPLACE FUNCTION player_performance(p_player_id INT, match_date_start DATE, match_date_end DATE)
RETURNS TABLE(player_name VARCHAR, team_name VARCHAR, score_type VARCHAR, total_score INT)
LANGUAGE plpgsql
AS
$$
BEGIN
RETURN QUERY
SELECT p.player_name, t.team_name, s.score_type, SUM(s.score_value):: INT AS total_score FROM players p
INNER JOIN teams t ON p.team_id = t.team_id
INNER JOIN scores s ON s.team_id = t.team_id
INNER JOIN matches m ON m.match_id = s.match_id
WHERE p.player_id = p_player_id AND m.match_date BETWEEN match_date_start AND match_date_end
GROUP BY p.player_name, t.team_name, s.score_type
ORDER BY total_score DESC;
END
$$;

-- Calling the stored procedure player_performance
SELECT * FROM player_performance(1, '2024-09-20', '2024-09-30');

-- Adding a Unique Constraint to the table player_statistics
ALTER TABLE player_statistics ADD CONSTRAINT unique_player_statistics UNIQUE (player_id, match_id, score_type);

-- Creating a trigger to update the PlayerStatistics table whenever a new record is inserted into the Scores table.
CREATE OR REPLACE FUNCTION update_player_statistics()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
INSERT INTO player_statistics (player_id, match_id, score_type, score_value) VALUES (NEW.team_id, NEW.match_id, NEW.score_type, NEW.score_value) ON CONFLICT (player_id, match_id, score_type) DO UPDATE SET score_value = player_statistics.score_value + NEW.score_value;
RETURN NEW;
END
$$;
CREATE TRIGGER after_scores_insert_trigger
AFTER INSERT ON scores
FOR EACH ROW
EXECUTE FUNCTION update_player_statistics();

-- Calling the Trigger by inserting a value
INSERT INTO scores (match_id, team_id, score_type, score_value) VALUES (1, 1, 'Goals', 2);
SELECT * FROM player_statistics;

-- Creating Index for the column league_name in the leagues table 
CREATE INDEX idx_leagues_league_name ON leagues (league_name);

-- Creating Index for the column league_id in the teams table
CREATE INDEX idx_teams_league_id ON teams (league_id);

-- Creating Index for the column team_name in the teams table
CREATE INDEX idx_teams_team_name ON teams (team_name);

-- Creating Index for the column team_id in the players table
CREATE INDEX idx_players_team_id ON players (team_id);

-- Creating Index for the column player_name in the players table
CREATE INDEX idx_players_player_name ON players (player_name);

-- Creating Index for the column league_id in the matches table
CREATE INDEX idx_matches_league_id ON matches (league_id);

-- Creating Index for the column match_date in the matches table
CREATE INDEX idx_matches_match_date ON matches (match_date);

-- Creating Index for the column team_id1 in the matches table
CREATE INDEX idx_matches_team_id1 ON matches (team_id1);

-- Creating Index for the column team_id2 in the matches table
CREATE INDEX idx_matches_team_id2 ON matches (team_id2);

-- Creating Index for the column match_id in the scores table
CREATE INDEX idx_scores_match_id ON scores (match_id);

-- Creating Index for the column team_id in the scores table
CREATE INDEX idx_scores_team_id ON scores (team_id);

-- Creating Index for the column score_type in the scores table
CREATE INDEX idx_scores_score_type ON scores (score_type);

-- Creating Index for the column player_id in the player_statistics table
CREATE INDEX idx_player_statistics_player_id ON player_statistics (player_id);

-- Creating Index for the column match_id in the player_statistics table
CREATE INDEX idx_player_statistics_match_id ON player_statistics (match_id);

-- Creating a view to display  views to display player-wise statistics. 
CREATE OR REPLACE VIEW player_statistics_view AS
SELECT p.player_id, p.player_name, t.team_name, SUM(s.score_value) AS TotalScore, COUNT(CASE WHEN s.score_type = 'Wins' THEN 1 END) AS Wins, COUNT(CASE WHEN s.score_type = 'Losses' THEN 1 END) AS Losses, COUNT(CASE WHEN s.score_type = 'Draws' THEN 1 END) AS Draws FROM players p
INNER JOIN teams t ON p.team_id = t.team_id
INNER JOIN scores s ON s.team_id = t.team_id
INNER JOIN matches m ON m.match_id = s.match_id
GROUP BY p.player_id, p.player_name, t.team_name;

-- Displaying the player_statistics_view View
SELECT * FROM player_statistics_view;

-- Creating a view to display  views to display team-wise statistics.
CREATE OR REPLACE VIEW team_statistics_view AS
SELECT t.team_id, t.team_name, COUNT(CASE WHEN s.score_type = 'Wins' THEN 1 END) AS Wins, COUNT(CASE WHEN s.score_type = 'Losses' THEN 1 END) AS Losses, COUNT(CASE WHEN s.score_type = 'Draws' THEN 1 END) AS Draws, SUM(s.score_value) AS TotalScore FROM teams t
INNER JOIN scores s ON s.team_id = t.team_id
INNER JOIN matches m ON m.match_id = s.match_id
GROUP BY t.team_id, t.team_name;

-- Displaying the team_statistics_view View
SELECT * FROM team_statistics_view;

-- Creating a stored procedure to ingest scoring data from external sources.
CREATE OR REPLACE FUNCTION ingest_scoring_data(p_match_id INT, p_team_id INT, p_score_type VARCHAR, p_score_value INT) 
RETURNS VOID
LANGUAGE plpgsql
AS
$$
BEGIN
INSERT INTO scores (match_id, team_id, score_type, score_value) VALUES (p_match_id, p_team_id, p_score_type, p_score_value) ON CONFLICT (match_id, team_id, score_type) DO NOTHING;
IF NOT FOUND THEN RAISE NOTICE 'Score data for match_id %, team_id % already exists. Skipping insert.', p_match_id, p_team_id;
END IF;
END
$$;

-- Calling the stored procedure ingest_scoring_data 
SELECT ingest_scoring_data(1, 1, 'Goals', 3);

-- Creating a stored procedure to update player statistics in real-time.
CREATE OR REPLACE FUNCTION update_statistics()
RETURNS VOID
LANGUAGE plpgsql
AS
$$
BEGIN    
INSERT INTO player_statistics (player_id, match_id, score_type, score_value)
SELECT p.player_id, s.match_id, s.score_type, s.score_value FROM scores s
INNER JOIN teams t ON s.team_id = t.team_id
INNER JOIN players p ON p.team_id = t.team_id
ON CONFLICT (player_id, match_id, score_type) DO UPDATE SET score_value = player_statistics.score_value + EXCLUDED.score_value;
END
$$;

-- Calling the stored procedure update_statistics 
SELECT update_statistics();





