-- conversion analysis
-- how many events go to a url with /api/v1/user
-- (how many times a user goes to the payment page)


-- measures conversion rates for every URL

WITH deduped_events AS (                -- removes duplicates
    SELECT
    url, host, user_id,event_time
    FROM events
    GROUP BY 1,2,3,4
), clean_events AS (                    -- cleans event_time
    SELECT *, DATE(event_time) as event_date FROM deduped_events
    WHERE user_id IS NOT NULL
    ORDER BY user_id, event_time
), converted AS (                       -- for every event, finds later events on the same day by the same user
    SELECT 
        ce1.user_id,
        ce1.event_time,
        ce1.url,
        MAX(CASE WHEN ce2.url = '/api/v1/user' THEN 1 ELSE 0 END) AS converted
    FROM clean_events ce1
    JOIN clean_events ce2
        ON ce2.user_id = ce1.user_id
        AND ce2.event_date = ce1.event_date
        AND ce2.event_time > ce1.event_time
    GROUP BY 1, 2,3
)


-- counts the number of times the url appears 
-- CAST(SUM(converted) conversion rate (% of events for url hitting /api/v1/user the same day)
SELECT
    url,
    COUNT(*) AS total_events,
    CAST(SUM(converted) AS REAL) / COUNT(*) AS conversion_rate
FROM converted
GROUP BY url
HAVING 
    1=1
    -- AND CAST(SUM(converted) AS REAL) / COUNT(*) > 0
    -- AND COUNT(*) > 100
ORDER BY conversion_rate desc


