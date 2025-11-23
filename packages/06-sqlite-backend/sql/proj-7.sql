/*
{"innings.overs.deliveries.runs":0}
*/
.timer on

WITH vars as (
	SELECT 'innings' AS p0, 'overs' AS p1, 'deliveries' AS p2, 'runs' AS p3
)
SELECT m.id, (
	WITH
	p0_each AS (
                SELECT
			CASE json_type(m.doc, '$.' || (SELECT p0 FROM vars))
				WHEN 'array' THEN je.key
				ELSE null
			END AS key,
			CASE json_type(m.doc, '$.' || (SELECT p0 FROM vars))
				WHEN 'array' THEN je.value
				ELSE json_extract(m.doc, '$.' || (SELECT p0 FROM vars))
			END AS value
		FROM
		(SELECT 1) AS dummy
		LEFT JOIN json_each(m.doc, '$.' || (SELECT p0 FROM vars)) AS je
		ON json_type(m.doc, '$.' || (SELECT p0 FROM vars)) = 'array'
	),
	p1_each AS (
		SELECT
			p0_each.key AS p0_key,
			p0_each.value AS p0_value,
			CASE json_type(p0_each.value, '$.' || (SELECT p1 FROM vars))
				WHEN 'array' THEN je.key
				ELSE null
			END AS key,
			CASE json_type(p0_each.value, '$.' || (SELECT p1 FROM vars))
				WHEN 'array' THEN je.value
				ELSE json_extract(p0_each.value, '$.' || (SELECT p1 FROM vars))
			END AS value
		FROM
		p0_each
		CROSS JOIN (SELECT 1) AS dummy
		LEFT JOIN json_each(p0_each.value, '$.' || (SELECT p1 FROM vars)) AS je
		ON json_type(p0_each.value, '$.' || (SELECT p1 FROM vars)) = 'array'
	),
	p2_each_mod AS (
		SELECT
			p1_each.p0_key AS p0_key,
			p1_each.p0_value AS p0_value,
			p1_each.key AS p1_key,
			p1_each.value AS p1_value,
			CASE json_type(p1_each.value, '$.' || (SELECT p2 FROM vars))
				WHEN 'array' THEN je.key
				ELSE null
			END AS key,
			CASE json_type(p1_each.value, '$.' || (SELECT p2 FROM vars))
				WHEN 'array' THEN json_remove(je.value, '$.' || (SELECT p3 FROM vars))
				ELSE json_remove(json_extract(p1_each.value, '$.' || (SELECT p2 FROm vars)), '$.' || (SELECT p3 FROM vars))
			END AS value
		FROM p1_each
		CROSS JOIN
		(SELECT 1) AS dummy
		LEFT JOIN json_each(p1_each.value, '$.' || (SELECT p2 FROM vars)) AS je
		ON json_type(p1_each.value, '$.' || (SELECT p2 FROM vars)) = 'array'
	),
	p1_each_mod AS (
		SELECT
			p2_each_mod.p0_key AS p0_key,
			p2_each_mod.p0_value AS p0_value,
			p2_each_mod.p1_key AS key,
			json_replace(
				p2_each_mod.p1_value,
				'$.' || (SELECT p2 FROM vars),
				CASE
					WHEN p2_each_mod.key IS NULL THEN json(p2_each_mod.value)
					ELSE json_group_array(json(p2_each_mod.value))
				END
			) AS value
		FROM p2_each_mod
		GROUP BY p2_each_mod.p1_key
	),
	p0_each_mod AS (
		SELECT
			p1_each_mod.p0_key AS key,
			json_replace(
				p1_each_mod.p0_value,
				'$.' || (SELECT p1 FROM vars),
				CASE
					WHEN p1_each_mod.key IS NULL THEN json(p1_each_mod.value)
					ELSE json_group_array(json(p1_each_mod.value))
				END
			) AS value
		FROM p1_each_mod
		GROUP BY p1_each_mod.p0_key
	)
	SELECT
		CASE
			WHEN p0_each_mod.key IS NULL THEN json(p0_each_mod.value)
			ELSE json_group_array(json(p0_each_mod.value))
		END
	FROM p0_each_mod
)
FROM matches AS m
LIMIT 10;
