SELECT
	m.id,
	(
		SELECT json_group_array(obj)
		FROM (
			SELECT json_group_object(je_2.key, je_2.value) AS obj
			FROM json_each(m.doc, '$.innings') AS je_1
			CROSS JOIN json_each(je_1.value) AS je_2
			WHERE je_2.key <> 'overs'
			GROUP BY je_1.key
		)
	)
FROM matches AS m
LIMIT 3
