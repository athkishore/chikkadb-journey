/*
{"innings.overs.deliveries":0}
*/

WITH vars as (
	SELECT 'info' AS p0, 'toss' AS p1
)
SELECT m.id, (
	WITH
	p0_each AS (
                SELECT
			CASE json_type(m.doc, '$.' || (SELECT p0 FROM vars))
				WHEN 'array' THEN je.value
				ELSE json_extract(m.doc, '$.' || (SELECT p0 FROM vars))
			END AS value
		FROM
		(SELECT 1) AS dummy
		LEFT JOIN json_each(m.doc, '$.' || (SELECT p0 FROM vars)) AS je
		ON json_type(m.doc, '$.' || (SELECT p0 FROM vars)) = 'array'
	)
	SELECT
		CASE json_type(m.doc, '$.' || (SELECT p0 FROM vars))
			WHEN 'array' THEN json_group_array(json_remove(p0_each.value, '$.' || (SELECT p1 FROM vars)))
			WHEN 'object' THEN
				json_remove(p0_each.value, '$.' || (SELECT p1 FROM vars))
			ELSE 2
		END
	FROM p0_each
)
FROM matches AS m
LIMIT 10;
