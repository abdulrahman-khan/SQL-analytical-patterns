-- select * from game_details limit 1;
-- select * from games limit 1

-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'game_details';

-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'games';



-- State Change Tracking for Players
-- A player entering the league should be New
-- A player leaving the league should be Retired
-- A player staying in the league should be Continued Playing
-- A player that comes out of retirement should be Returned from Retirement
-- A player that stays out of the league should be Stayed Retired

WITH last_season AS (
    SELECT DISTINCT 
        player_name,
        current_season
    FROM players
    WHERE current_season = '2021'
),
this_season AS (
    SELECT DISTINCT
        player_name,
        current_season as season
    FROM players  
    WHERE current_season = '2022'
),
players_growth_accounting AS (
    SELECT 
        COALESCE(t.player_name, l.player_name) as player_name,
        COALESCE(l.current_season, t.season - 1) as last_season,
        COALESCE(t.season, l.current_season + 1) as this_season,
        CASE 
            WHEN l.player_name IS NULL THEN 'New'
            WHEN l.current_season = t.season - 1 THEN 'Continued Playing'  
            WHEN t.season IS NULL THEN 'Retired'
            WHEN l.current_season < t.season - 1 THEN 'Returned from Retirement'
            ELSE 'Stayed Retired'
        END as old_state,
        CASE
            WHEN l.player_name IS NULL THEN 'New'
            WHEN t.player_name IS NOT NULL THEN 'Continued Playing'
            WHEN t.player_name IS NULL THEN 'Retired' 
            ELSE 'Unknown'
        END as current_state
    FROM this_season t
    FULL OUTER JOIN last_season l ON t.player_name = l.player_name
)
SELECT 
    player_name,
    last_season,
    this_season, 
    old_state,
    current_state
FROM players_growth_accounting
ORDER BY old_state, player_name;