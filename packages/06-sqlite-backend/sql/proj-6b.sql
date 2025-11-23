/*
{"innings.overs.deliveries":0}
*/
.timer on

WITH vars as (
	SELECT 'innings' AS p0, 'overs' AS p1, 'deliveries' AS p2
)
SELECT m.id, (
	WITH
	p0_each AS (
                SELECT
			CASE json_type(m.doc, '$.' || (SELECT p0 FROM vars))
				WHEN 'array' THEN je.key
				ELSE null
			END AS key,
			CASE json_type(m.doc, '$.' || (SELECT p0 FROM vars))
				WHEN 'array' THEN je.value
				ELSE jsonb_extract(m.doc, '$.' || (SELECT p0 FROM vars))
			END AS value
		FROM
		(SELECT 1) AS dummy
		LEFT JOIN jsonb_each(m.doc, '$.' || (SELECT p0 FROM vars)) AS je
		ON json_type(m.doc, '$.' || (SELECT p0 FROM vars)) = 'array'
	),
	p1_each_mod AS (
		SELECT
			p0_each.key AS p0_key,
			p0_each.value AS p0_value,
			CASE json_type(p0_each.value, '$.' || (SELECT p1 FROM vars))
				WHEN 'array' THEN je.key
				ELSE null
			END AS key,
			CASE json_type(p0_each.value, '$.' || (SELECT p1 FROM vars))
				WHEN 'array' THEN jsonb_remove(je.value, '$.' || (SELECT p2 FROM vars))
				ELSE jsonb_remove(jsonb_extract(p0_each.value, '$.' || (SELECT p1 FROm vars)), '$.' || (SELECT p2 FROM vars))
			END AS value
		FROM p0_each
		CROSS JOIN
		(SELECT 1) AS dummy
		LEFT JOIN jsonb_each(p0_each.value, '$.' || (SELECT p1 FROM vars)) AS je
		ON json_type(p0_each.value, '$.' || (SELECT p1 FROM vars)) = 'array'
	),
	p0_each_mod AS (
		SELECT
			p1_each_mod.p0_key as key,
			jsonb_replace(
				p1_each_mod.p0_value,
				'$.' || (SELECT p1 FROM vars),
				CASE
					WHEN p1_each_mod.key IS NULL THEN jsonb(p1_each_mod.value)
					ELSE jsonb_group_array(jsonb(p1_each_mod.value))
				END
			) AS value
		FROM p1_each_mod
		GROUP BY p1_each_mod.p0_key
	)
	SELECT
		CASE
			WHEN p0_each_mod.key IS NULL THEN jsonb(p0_each_mod.value)
			ELSE jsonb_group_array(jsonb(p0_each_mod.value))
		END
	FROM p0_each_mod
)
FROM matches AS m
LIMIT 10;
