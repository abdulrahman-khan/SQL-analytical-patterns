select * from fct_game_details

-- Query 2: GROUPING SETS for Efficient Aggregations
-- A query that uses GROUPING SETS to do efficient aggregations of game_details data
-- Aggregate this dataset along the following dimensions

-- player and team- who scored the most points playing for one team?

-- player and season - who scored the most points in one season?

-- team - which team has won the most games?





WITH games_with_season AS (
    SELECT 
        gd.*,
        g.season
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
),
combined AS (
    SELECT 
        COALESCE(gws.player_name, 'N/A') as player_name_NA,
        COALESCE(gws.team_abbreviation, 'N/A') as team_abbreviation_NA,
        COALESCE(CAST(gws.season AS TEXT), 'N/A') as season_NA,
        gws.*,
        -- finding wins
        CASE 
            WHEN gws.plus_minus > 0 THEN 1
            ELSE 0
        END as likely_win
    FROM games_with_season gws
)

SELECT 
    COALESCE(player_name_NA, '(overall)') as player_name, 
    COALESCE(team_abbreviation_NA, '(overall)') as team_abbreviation,
    COALESCE(season_NA, '(overall)') as season,
    COUNT(1) as number_of_games,
    COUNT(DISTINCT player_name) as unique_players,
    COUNT(DISTINCT team_abbreviation) as unique_teams,
    SUM(pts) as total_points,
    ROUND(AVG(pts)::NUMERIC, 2) as avg_points_per_game,
    MAX(pts) as max_points_single_game,
    COUNT(CASE WHEN pts >= 20 THEN 1 END) as games_with_20plus_points,
    COUNT(CASE WHEN pts >= 30 THEN 1 END) as games_with_30plus_points,
    SUM(likely_win) as estimated_wins,
    ROUND(AVG(likely_win)::NUMERIC, 3) as estimated_win_rate,
    SUM(reb) as total_rebounds,
    SUM(ast) as total_assists,
    SUM(stl) as total_steals,
    SUM(blk) as total_blocks,
    ROUND(AVG(reb)::NUMERIC, 2) as avg_rebounds_per_game,
    ROUND(AVG(ast)::NUMERIC, 2) as avg_assists_per_game


FROM combined 
GROUP BY GROUPING SETS (
    -- Answers: "who scored the most points playing for one team?"
    (player_name_NA, team_abbreviation_NA),
    -- Answers: "who scored the most points in one season?"
    (player_name_NA, season_NA),
    -- Answers: "which team has won the most games?"
    (team_abbreviation_NA)
    
)
ORDER BY total_points DESC NULLS LAST;