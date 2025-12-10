/* { "innings.team": 1, 'innings.overs.deliveries.bowler': 1, "info.match_type": 1 } */
.timer on
SELECT (
	WITH p0 AS (
		SELECT
			je.key AS p0_k,
			je.type AS p0_t,
			je.value AS p0_v
		FROM json_each(c.doc) AS je
		WHERE je.key IN ('info', 'innings')
	),
	p0_each AS (
		SELECT
			p0.p0_k AS p0_k,
			p0.p0_t AS p0_t,
			CASE p0.p0_t
				WHEN 'array' THEN je.key
				ELSE null
			END as p0_each_i,
			CASE p0.p0_t
				WHEN 'array' THEN je.value
				ELSE p0.p0_v
			END as p0_each_v
		FROM
			p0
			CROSS JOIN (SELECT 1)
			LEFT JOIN json_each(p0.p0_v) AS je ON p0.p0_t = 'array'
	),
	p1 AS (
		SELECT
			p0_each.p0_k AS p0_k,
			p0_each.p0_t AS p0_t,
			p0_each.p0_each_i AS p0_each_i,
			je.key AS p1_k,
			je.type AS p1_t,
			je.value AS p1_v
		FROM
			p0_each
			CROSS JOIN (SELECT 1)
			LEFT JOIN json_each(p0_each.p0_each_v) AS je
			WHERE (
				(p0_each.p0_k = 'info' AND je.key IN ('match_type', 'teams'))
				OR (p0_each.p0_k = 'innings' AND je.key IN ('team', 'overs'))
			)
	),
	p0_each_mod AS (
		SELECT
			p1.p0_k AS p0_k,
			p1.p0_t AS p0_t,
			p1.p0_each_i AS p0_each_i,
			json_group_object(p1.p1_k, CASE p1.p1_t WHEN 'array' THEN json(p1.p1_v) WHEN 'object' THEN json(p1.p1_v) ELSE p1.p1_v END) AS p0_each_v
		FROM p1
		GROUP BY p1.p0_k, p1.p0_each_i
	),
	p0_mod AS (
		SELECT
			p0_each_mod.p0_k AS p0_k,
			p0_each_mod.p0_t AS p0_t,
			CASE p0_each_mod.p0_t
				WHEN 'array' THEN json_group_array(json(p0_each_mod.p0_each_v))
				ELSE p0_each_mod.p0_each_v
			END AS p0_v
		FROM p0_each_mod
		GROUP BY p0_each_mod.p0_k
	)
	SELECT json_group_object(p0_mod.p0_k, json(p0_mod.p0_v))
	FROM p0_mod
)
FROM matches AS c
LIMIT 5;
