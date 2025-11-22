.timer on
--PRAGMA journal_mode = WAL;

-- Reduce fsync overhead while keeping reasonable durability
--PRAGMA synchronous = NORMAL;

-- Increase page cache to reduce disk I/O
--PRAGMA cache_size = 10000;
--PRAGMA temp_store = MEMORY;

-- Enable memory-mapped I/O for large databases (optional, depends on OS)
--PRAGMA mmap_size = 1073741824; -- 1GB

-- Optional: adjust locking mode for single connection
--PRAGMA locking_mode = EXCLUSIVE;

-- Wrap multiple queries in a transaction for faster execution
--BEGIN TRANSACTION;

SELECT COUNT(DISTINCT(c.id))
    FROM matches as c
    WHERE EXISTS (
      WITH subtree(key, fullkey, type, value) AS (
        SELECT jt.key, jt.fullkey, jt.type, jt.value
        FROM json_tree(c.doc) AS jt
      ),
        condition_0 AS (
          SELECT 1 AS c0
          FROM subtree
          WHERE fullkey LIKE '$.info%."match_type"%' AND value = 'Test'
          LIMIT 1
        )      ,
        condition_1 AS (
          SELECT 1 AS c1
          FROM subtree
          WHERE fullkey LIKE '$.info%.teams%' AND value = 'India'
          LIMIT 1
        )      ,
        condition_2 AS (
          SELECT 1 AS c2
          FROM subtree
          WHERE fullkey LIKE '$.info%.teams%' AND value = 'Australia'
          LIMIT 1
        )      ,
        condition_3 AS (
          SELECT 1 AS c3
          FROM subtree
          WHERE fullkey LIKE '$.innings%.overs%.deliveries%.runs%.extras%' AND value = 5
          LIMIT 1
        )
      SELECT 1
      FROM condition_0 c0
      FULL OUTER JOIN condition_1 c1 ON 1=1
      FULL OUTER JOIN condition_2 c2 ON 1=1
      FULL OUTER JOIN condition_3 c3 ON 1=1
      WHERE
        ((c0 IS NOT NULL) AND ((c1 IS NOT NULL) OR (c2 IS NOT NULL)) AND (c3 IS NOT NULL))
    );

--COMMIT;
