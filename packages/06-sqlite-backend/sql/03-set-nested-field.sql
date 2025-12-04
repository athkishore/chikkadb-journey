.timer on
UPDATE users
SET doc = jsonb_set(
	doc,
	'$.phones[' || idx || '].calls',
	ifnull(jsonb_extract(doc, '$.phones[' || idx || '].calls'), 0) + 1
)
FROM (
	SELECT users.id AS id, je.key AS idx
	FROM users, jsonb_each(users.doc, '$.phones') AS je
	WHERE jsonb_extract(je.value, '$.type') = 'mobile'
) sub
WHERE users.id = sub.id;

