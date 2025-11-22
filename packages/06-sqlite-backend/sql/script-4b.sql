.timer on
SELECT COUNT(DISTINCT(c.id))
FROM matches AS c
WHERE EXISTS (
	WITH
	condition_0 AS (
		SELECT 1 AS c0
		FROM jsonb_each(c.doc, '$.info') AS c0_info
		WHERE
		CASE c0_info.key
			WHEN 'match_type' THEN
				CASE c0_info.type
					WHEN 'array' THEN EXISTS (
						SELECT 1 FROM jsonb_each(c0_info.value) AS match_type WHERE match_type.value = 'Test'
					)
					ELSE c0_info.value = 'Test'
				END
			ELSE 0
		END
	),
	condition_1 AS (
		SELECT 1 AS c1
		FROM jsonb_each(c.doc, '$.info') AS c1_info
		WHERE
		CASE c1_info.key
			WHEN 'teams' THEN
				CASE c1_info.type
					WHEN 'array' THEN EXISTS (
						SELECT 1 FROM jsonb_each(c1_info.value) AS teams WHERE teams.value = 'India'
					)
					ELSE c1_info.value = 'India'
				END
			ELSE 0
		END
	),
	condition_2 AS (
		SELECT 1 AS c2
		FROM jsonb_each(c.doc, '$.info') AS c2_info
		WHERE
		CASE c2_info.key
			WHEN 'teams' THEN
				CASE c2_info.type
					WHEN 'array' THEN EXISTS (
						SELECT 1 FROM jsonb_each(c2_info.value) AS teams WHERE teams.value = 'Australia'
					)
					ELSE c2_info.value = 'Australia'
				END
			ELSE 0
		END
	),
	condition_3 AS (
		SELECT 1 AS c3
		FROM jsonb_each(c.doc, '$.innings') AS c3_innings
		WHERE EXISTS (
			SELECT 1 FROM jsonb_each(c3_innings.value, '$.overs') AS c3_innings_overs
			WHERE EXISTS (
				SELECT 1 FROM jsonb_each(c3_innings_overs.value, '$.deliveries') AS c3_innings_overs_deliveries
				WHERE EXISTS (
					SELECT 1 FROM jsonb_each(c3_innings_overs_deliveries.value, '$.runs') AS c3_innings_overs_deliveries_runs
					WHERE
					CASE c3_innings_overs_deliveries_runs.key
						WHEN 'extras' THEN
							CASE c3_innings_overs_deliveries_runs.type
								WHEN 'array' THEN EXISTS (
									SELECT 1 FROM jsonb_each(c3_innings_overs_deliveries_runs.value, '$.extras') AS c3_innings_overs_deliveries_runs_extras
									WHERE c3_innings_overs_deliveries_runs_extras.value = 5
								)
								ELSE c3_innings_overs_deliveries_runs.value = 5
							END
						ELSE 0
					END
				)
			)
		)
	)
	SELECT 1 FROM condition_0 c0
	FULL OUTER JOIN condition_1 c1 ON 1=1
	FULL OUTER JOIN condition_2 c2 ON 1=1
	FULL OUTER JOIN condition_3 c3 ON 1=1
	WHERE
		(c0 IS NOT NULL) AND ((c1 IS NOT NULL) OR (c2 IS NOT NULL)) AND (c3 IS NOT NULL)
);
