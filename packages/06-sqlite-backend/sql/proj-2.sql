/*
{"info.match_type":1}
*/
.timer on

SELECT
	id,
	json_object(
		'innings',
		CASE json_type(doc, '$.innings')
			WHEN 'array' THEN (
				SELECT json_group_array(
					json_object(
						'team',
						json_extract(je.value, '$.team')
					)
				)
				FROM json_each(doc, '$.innings') AS je
			)
			ELSE json_object(
				'team',
				json_extract(doc, '$.team')
			)
		END
	)
FROM
	matches
LIMIT 10;
