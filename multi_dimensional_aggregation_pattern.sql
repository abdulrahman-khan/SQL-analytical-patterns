

-- Perform multi-dimensional aggregation of web traffic data using
--           GROUPING SETS to generate metrics at different granularities.

-- Multi-dimensional aggregation / OLAP-style reporting.
-- GROUPING SETS allows aggregation at multiple levels in a single query:
--     Full detail: (referrer, browser_type, os_type)
--     Partial detail: (referrer), (browser_type), (os_type)
--     Overall summary: ()




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
)

SELECT
    COALESCE(referrer_mapped, '(overall)') AS referrer,
    COALESCE(browser_type_NA, '(overall)') AS browser_type,
    COALESCE(os_type_NA, '(overall)') AS os_type,
    COUNT(1) AS number_of_site_hits,
    COUNT(CASE WHEN url ='/signup' then 1 END) as number_of_sign_up_visits,
    COUNT(CASE WHEN url ='/contact' then 1 END) as number_of_contact_visits,
    COUNT(CASE WHEN url ='/login' then 1 END) as number_of_login_visits
from combined 
GROUP BY GROUPING SETS (
    (referrer_mapped, browser_type_NA, os_type_NA),
    (os_type_NA),
    (browser_type_NA),
    (referrer_mapped),
    ()
)

ORDER BY count(1) desc









