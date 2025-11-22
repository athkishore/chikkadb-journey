/*
{"meta":0,"innings.overs":0}
*/

SELECT
	(
		SELECT json_group_object(
			je_0.key,
			CASE je_0.key
				WHEN 'innings' THEN
					CASE json_type(je_0.value)
						WHEN 'array' THEN (
							SELECT json_group_array(
								json_remove(je_1.value, '$.overs')
							)
							FROM json_each(je_0.value) AS je_1
						)
						WHEN 'object' THEN (
							SELECT json_group_object(
								je_1.key,
								je_1.value
							)
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
