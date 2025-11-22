/*
{"info":1}
*/

SELECT
	id,
	json_object(
		'info',
		json_extract(doc, '$.info')
	)
FROM
	matches
LIMIT 10;
