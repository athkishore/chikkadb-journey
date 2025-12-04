.timer on

--BEGIN TRANSACTION;

WITH vars AS (
	SELECT '1' AS new_node_id,
		'node 1' AS new_node_content,
		'0' AS parent_node_id,
		'1' AS graph_id
)
UPDATE graphs AS g
SET doc = jsonb_set(
	g.doc,
	'$.nodes',
	jsonb_insert(
		jsonb_extract(doc, '$.nodes'),
		'$[#]',
		jsonb_object(
			'id',
			(SELECT new_node_id FROM vars),
			'content',
			(SELECT new_node_content FROM vars)
		)
	),
	'$.adjList',
	(
		WITH _je AS (
			SELECT key, value
			FROM jsonb_each(
				jsonb_insert(
					jsonb_extract(doc, '$.adjList'),
					'$[#]',
					jsonb_object(
						'nodeId',
						(SELECT new_node_id FROM vars),
						'list',
						jsonb('[]')
					)
				)
			)
		)
		SELECT jsonb_group_array(
			CASE jsonb_extract(_je.value, '$.nodeId')
				WHEN (SELECT parent_node_id FROM vars)
					THEN jsonb_patch(
						_je.value,
						jsonb_object(
							'list',
							jsonb_insert(
								jsonb_extract(
									_je.value,
									'$.list'
								),
								'$[#]',
								(SELECT new_node_id FROM vars)
							)
						)
					)
				ELSE _je.value
			END
		)
		FROM _je
	)
)
--FROM (
--	SELECT graphs.id AS id, je.key AS parent_idx
--	FROM graphs, jsonb_each(graphs.doc, '$.adjList') AS je
--	WHERE jsonb_extract(je.value, '$.nodeId') = (SELECT parent_node_id FROM vars)
--) sub
WHERE g.id = (SELECT graph_id FROM vars);
-- AND sub.id = g.id;


--COMMIT;

SELECT id, json(doc) FROM graphs;
