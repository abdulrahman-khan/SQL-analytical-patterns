-- Query 3: Window Functions Analysis


-- Part A: Most games a team has won in a 90-game stretch
WITH games_augmented AS (
    SELECT 
        g.home_team_id as team_id,
        g.game_date_est,
        g.game_id,
        g.season,
        CASE WHEN g.home_team_wins = 1 THEN 1 ELSE 0 END as win
    FROM games g

    UNION ALL

    SELECT 
        g.visitor_team_id as team_id,
        g.game_date_est,
        g.game_id,
        g.season,
        CASE WHEN g.home_team_wins = 0 THEN 1 ELSE 0 END as win
    FROM games g
),
team_games_aggregated AS (
    SELECT 
        team_id,
        game_date_est,
        season,
        SUM(win) as wins_on_date
    FROM games_augmented
    GROUP BY team_id, game_date_est, season
),
team_games_windowed AS (
    SELECT 
        team_id,
        game_date_est,
        season,
        wins_on_date,
        ROW_NUMBER() OVER (PARTITION BY team_id ORDER BY game_date_est) AS game_number,
        SUM(wins_on_date) OVER (
            PARTITION BY team_id
            ORDER BY game_date_est
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) AS wins_90_game_window,
        COUNT(*) OVER (
            PARTITION BY team_id
            ORDER BY game_date_est
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) AS games_in_90_window,
        SUM(wins_on_date) OVER (
            PARTITION BY team_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS total_wins
    FROM team_games_aggregated
)
SELECT 
    team_id,
    NULL as player_name,
    game_date_est,
    wins_90_game_window as metric_value,
    games_in_90_window as games_in_window,
    CAST(wins_90_game_window AS REAL) / NULLIF(games_in_90_window, 0) as win_rate_90_games,
    CAST(wins_90_game_window AS REAL) / NULLIF(total_wins, 0) as pct_of_total_wins
FROM team_games_windowed
WHERE games_in_90_window = 90
  AND wins_90_game_window = (
    SELECT MAX(wins_90_game_window)
    FROM team_games_windowed
    WHERE games_in_90_window = 90
  );


-- =================================
-- Part B: LeBron James consecutive games with 10+ points
WITH lebron_games_augmented AS (
    SELECT 
        gd.player_name,
        COALESCE(gd.pts, 0) as pts,
        g.game_date_est,
        g.season,
        CASE WHEN gd.pts >= 10 THEN 1 ELSE 0 END AS scored_10_plus
    FROM game_details gd
    JOIN games g ON gd.game_id = g.game_id
    WHERE gd.player_name = 'LeBron James'
),
lebron_games_aggregated AS (
    SELECT 
        player_name,
        game_date_est,
        season,
        MAX(pts) as pts,
        MAX(scored_10_plus) as scored_10_plus
    FROM lebron_games_augmented
    GROUP BY player_name, game_date_est, season
),
lebron_games_windowed AS (
    SELECT 
        player_name,
        game_date_est,
        season,
        pts,
        scored_10_plus,
        ROW_NUMBER() OVER (ORDER BY game_date_est) AS game_sequence,
        SUM(scored_10_plus) OVER (
            ORDER BY game_date_est
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) AS games_10plus_in_90,
        COUNT(*) OVER () AS total_games_played
    FROM lebron_games_aggregated
)
SELECT 
    NULL as team_id,
    player_name,
    game_date_est,
    games_10plus_in_90 as metric_value,
    90 as games_in_window,
    CAST(games_10plus_in_90 AS REAL) / 90 as win_rate_90_games,
    CAST(games_10plus_in_90 AS REAL) / NULLIF(total_games_played, 0) as pct_of_total_wins
FROM lebron_games_windowed
WHERE games_10plus_in_90 = (
    SELECT MAX(games_10plus_in_90)
    FROM lebron_games_windowed
);
