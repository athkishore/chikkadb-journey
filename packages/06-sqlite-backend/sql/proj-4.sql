/*
{"meta":0, "info":0, "innings.overs":0}
*/

SELECT (
	SELECT json_group_object(
		je_0.key,
		CASE je_0.key
			WHEN 'innings' THEN
				CASE json_type(je_0.value)
					WHEN 'array' THEN (
						SELECT json_group_array(obj)
						FROM (
							SELECT json_group_object(je_2.key, je_2.value) AS obj
							FROM json_each(je_0.value) AS je_1
							CROSS JOIN json_each(je_1.value) AS je_2
							WHERE je_2.key <> 'overs'
							GROUP BY je_1.key
						)
					)
					WHEN 'object' THEN (
						SELECT json_group_object(je_1.key, je_1.value)
						FROM json_each(je_0.value) AS je_1
						WHERE je_1.key <> 'overs'
					)
					ELSE je_0.value
				END
			ELSE je_0.value
		END
	)
	FROM json_each(doc) AS je_0
	WHERE key NOT IN ('meta', 'info')
)
FROM matches
LIMIT 10;
