.timer on
SELECT
	json_object(
		'innings',
		(
			WITH p0 AS (
				SELECT
					CASE json_type(c.doc, '$.innings')
						WHEN 'array' THEN je.key
						ELSE  null
					END AS key,
					json_type(c.doc, '$.innings') AS type,
					CASE json_type(c.doc, '$.innings')
						WHEN 'array' THEN je.value
						ELSE json_extract(c.doc, '$.innings')
					END AS value
				FROM
					(SELECT 1)
					LEFT JOIN json_each(c.doc, '$.innings') AS je ON json_type(c.doc, '$.innings') = 'array'
			),
			p1 AS (
				SELECT
					p0.key AS p0_key,
					p0.type AS p0_type,
					p0.value AS p0_value,
					CASE json_type(p0.value, '$.overs')
						WHEN 'array' THEN je.key
						ELSE null
					END AS key,
					json_type(p0.value, '$.overs') AS type,
					CASE json_type(p0.value, '$.overs')
						WHEN 'array' THEN je.value
						ELSE json_extract(p0.value, '$.overs')
					END AS value
				FROM
					p0
					CROSS JOIN (SELECT 1)
					LEFT JOIN json_each(p0.value, '$.overs') AS je ON json_type(p0.value, '$.overs') = 'array'
			),
			p2 AS (
				SELECT
					p1.p0_key AS p0_key,
					p1.p0_type AS p0_type,
					p1.p0_value AS p0_value,
					p1.key AS p1_key,
					p1.type AS p1_type,
					p1.value AS p1_value,
					CASE json_type(p1.value, '$.deliveries')
						WHEN 'array' THEN je.key
						ELSE null
					END AS key,
					json_type(p1.value, '$deliveries') AS type,
					CASE json_type(p1.value, '$.deliveries')
						WHEN 'array' THEN je.value
						ELSE json_extract(p1.value, '$.deliveries')
					END AS value
				FROM
					p1
					CROSS JOIN (SELECT 1)
					LEFT JOIN json_each(p1.value, '$.deliveries') AS je ON json_type(p1.value, '$.deliveries') = 'array'
			),
			p2_mod as (
				SELECT
					p2.p0_key AS p0_key,
					p2.p0_type AS p0_type,
					p2.p0_value AS p0_value,
					p2.p1_key AS p1_key,
					p2.p1_type AS p1_type,
					p2.p1_value AS p1_value,
					p2.key AS key,
					p2.type AS type,
					json_object('bowler', json_extract(p2.value, '$.bowler')) AS value
				FROM p2
			),
			p1_mod AS (
				SELECT
					p2_mod.p0_key AS p0_key,
					p2_mod.p0_type AS p0_type,
					p2_mod.p0_value AS p0_value,
					p2_mod.p1_key AS key,
					p2_mod.p1_type AS type,
					CASE p2_mod.p1_type
						WHEN 'array' THEN json_object('deliveries', json_group_array(json(p2_mod.value)))
						ELSE json_object('deliveries', json(p2_mod.value))
					END AS value
				FROM p2_mod
				GROUP BY p2_mod.p0_key, p2_mod.p1_key
			),
			p0_mod AS (
				SELECT
					p1_mod.p0_key AS key,
					p1_mod.p0_type AS type,
					CASE p1_mod.p0_type
						WHEN 'array' THEN json_object('overs', json_group_array(json(p1_mod.value)), 'team', json_extract(p1_mod.p0_value, '$.team'))
						ELSE json_object('overs', json(p1_mod.value))
					END AS value
				FROM p1_mod
				GROUP BY p1_mod.p0_key
			)
			SELECT
				CASE
					WHEN p0_mod.key IS null THEN CASE p0_mod.type WHEN 'array' THEN json('[]') ELSE json(p0_mod.value) END
					ELSE json_group_array(json(p0_mod.value))
				END
			FROM p0_mod
		)
	)
FROM
	matches AS c
LIMIT 20;
