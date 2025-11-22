.timer on
SELECT m.id
FROM matches AS m
WHERE 
--EXISTS (
--	SELECT 1 FROM json_tree(m.doc) AS jt WHERE jt.fullkey LIKE '$.info.dates[%' AND jt.value >= '2025-10-01'
--);
CASE json_type(m.doc, '$.info')
	WHEN 'object' THEN 
		CASE json_type(m.doc, '$.info.dates')
			WHEN 'object' THEN json_extract(m.doc, '$.info.dates') >= '2025-10-01'
			WHEN 'array' THEN (
				SELECT 1 FROM json_each(m.doc, '$.info.dates') AS date WHERE date.value >= '2025-10-01'
			)
			ELSE json_extract(m.doc, '$.info.dates') >= '2025-10-01'
		END
	WHEN 'array' THEN (
		SELECT 1 
		FROM json_each(m.doc, '$.info') AS info 
		WHERE
		CASE json_type(info.value, '$.dates')
			WHEN 'array' THEN (
				SELECT 1 FROM json_each(info.value, '$.dates') AS date WHERE date.value >= '2025-10-01'
			)
			ELSE json_extract(info.value, '$.dates') >= '2025-10-01'
		END
	)		
	ELSE 0
END;
