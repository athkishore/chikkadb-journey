.timer on
SELECT COUNT(DISTINCT c.id)
FROM matches AS c
WHERE EXISTS (
    WITH subtree AS (
        SELECT jt.key, jt.fullkey, jt.type, jt.value
        FROM json_tree(c.doc) AS jt
    )
    SELECT 1
    FROM (
        SELECT
            MAX(CASE WHEN fullkey LIKE '$.info%."match_type"%' AND value = 'Test' THEN 1 END) AS c0,
            MAX(CASE WHEN fullkey LIKE '$.info%.teams%' AND value = 'India' THEN 1 END) AS c1,
            MAX(CASE WHEN fullkey LIKE '$.info%.teams%' AND value = 'Australia' THEN 1 END) AS c2,
            MAX(CASE WHEN fullkey LIKE '$.innings[0].overs[0].deliveries[0].runs%.batter%' AND value = 4 THEN 1 END) AS c3
        FROM subtree
    ) t
    WHERE ((c0 IS NOT NULL) AND ((c1 IS NOT NULL) OR (c2 IS NOT NULL)) AND (c3 IS NOT NULL))
);
