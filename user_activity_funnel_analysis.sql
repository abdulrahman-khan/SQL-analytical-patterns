
-- user navigation path analysis with time spent on every page



WITH combined AS (
    SELECT 
        COALESCE(d.browser_type, 'N/A') as browser_type_NA,
        COALESCE(d.os_type, 'N/A') as os_type_NA,
        d.*, 
        we.*,
        CASE 
            WHEN we.referrer LIKE '%zachwilson%' THEN 'On Site'
            WHEN we.referrer LIKE '%eczackly%' THEN 'On Site'
            WHEN we.referrer LIKE '%dataengineer.io%' THEN 'On Site'
            WHEN we.referrer LIKE '%t.co%' THEN 'Twitter'
            WHEN we.referrer LIKE '%linkedin%' THEN 'LinkedIn'
            WHEN we.referrer LIKE '%instagram%' THEN 'On Instagram'
            WHEN we.referrer IS NULL then 'Direct'
            ELSE 'Other'
        END as referrer_mapped
    FROM events we JOIN devices d
    ON we.device_id = d.device_id
    -- 
), aggregated AS (
    SELECT 
        c1.user_id,
        c1.url as to_url, 
        c2.url as from_url,
        MIN(EXTRACT(EPOCH FROM (
            c1.event_time::timestamp - c2.event_time::timestamp
        ))) AS duration
    FROM combined c1
    JOIN combined c2 
        ON c1.user_id = c2.user_id 
        AND DATE(c1.event_time::timestamp) = DATE(c2.event_time::timestamp)
        AND c1.event_time::timestamp > c2.event_time::timestamp
    -- WHERE c1.user_id = 17509821797316000000
    GROUP BY c1.user_id, c1.url, c2.url
)

SELECT 
    to_url, from_url, 
    MIN(duration) as min_duration, 
    MAX(duration) as max_duration, 
    AVG(duration) as avg_duration, 
    COUNT(1) as number_of_users
from aggregated
group by to_url, from_url
HAVING count(1) > 100
LIMIT 100






-- select user_id, COUNT(*) from combined
-- group by user_id
-- ;











