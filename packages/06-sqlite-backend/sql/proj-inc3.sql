/* { "innings.team": 1, "info.match_type": 1 } */
.timer on
SELECT (
	WITH p0 AS (
		SELECT je.key, je.type, je.value
		FROM json_each(c.doc) AS je
		WHERE je.key IN ('innings', 'info')
	),
	p0_each AS (
		SELECT
			p0.key AS p0_key,
			CASE p0.type
				WHEN 'array' THEN je.key
				ELSE null
			END AS key,
			CASE p0.type
				WHEN 'array' THEN je.value
				ELSE p0.value
			END AS value
		FROM
			p0
			CROSS JOIN (SELECT 1)
			LEFT JOIN json_each(p0.value) AS je ON p0.type = 'array'
	),
	p1_mod AS (
		SELECT
			p0_each.p0_key AS p0_key,
			p0_each.key AS p0_index,
			je.key AS p1_key,
			je.type AS p1_type,
			je.value AS p1_value
		FROM
			p0_each
			LEFT JOIN json_each(p0_each.value) AS je
			WHERE (p0_each.p0_key = 'info' AND je.key = 'match_type') OR (p0_each.p0_key = 'innings' AND je.key = 'team')
	),
	p0_each_mod AS (
		SELECT
			p1_mod.p0_key AS p0_key,
			p1_mod.p0_index AS p0_index,
			json_group_object(p1_mod.p1_key, p1_mod.p1_value) AS value
		FROM p1_mod
		GROUP BY p1_mod.p0_key, p1_mod.p0_index
	),
	p0_mod AS (
		SELECT
			p0.key AS key,
			p0.type AS type,
			CASE p0.type
				WHEN 'array' THEN json_group_array(json(p0_each_mod.value))
				ELSE p0_each_mod.value
			END AS value
		FROM p0
		LEFT JOIN p0_each_mod ON p0.key = p0_each_mod.p0_key
		GROUP BY p0.key
	)
	SELECT json_group_object(p0_mod.key, json(p0_mod.value))
	FROM p0_mod
)
FROM matches AS c
LIMIT 5;
