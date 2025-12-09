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
						WHEN 'array' THEN je.value,
						ELSE json_extract(p0.value, '$.overs')
					END AS value
				FROM
					p0
					CROSS JOIN (SELECT 1)
					LEFT JOIN json_each(p0.value, '$.overs') AS je ON json_type(p0.value, '$.overs') = 'array'
			)
			SELECT
				CASE
					WHEN p0.key IS null THEN CASE p0.type WHEN 'array' THEN json('[]') ELSE json(p0.value) END
					ELSE json_group_array(json(p0.value))
				END
			FROM p0
		)
	)
FROM
	matches AS c
LIMIT 5;
