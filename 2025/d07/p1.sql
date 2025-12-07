DECLARE @n VARCHAR(MAX) = '.......S.......
...............
.......^.......
...............
......^.^......
...............
.....^.^.^.....
...............
....^.^...^....
...............
...^.^...^.^...
...............
..^...^.....^..
...............
.^.^.^.^.^...^.
...............';

DECLARE @vals TABLE (y INT, x INT, PRIMARY KEY (x, y));

INSERT INTO @vals (y, x)
SELECT
    s.ordinal AS y,
    v.x
FROM STRING_SPLIT(REPLACE(@n, CHAR(13), ''), CHAR(10), 1) AS s
CROSS APPLY
(
    SELECT
        g.value AS x,
        SUBSTRING(s.value, g.value, 1) AS val
    FROM GENERATE_SERIES(1, CONVERT(INT, LEN(s.value))) AS g
) AS v
WHERE
    v.val = '^';

DECLARE @splits TABLE (y INT, x INT, level INT, PRIMARY KEY (y, x) WITH (IGNORE_DUP_KEY=ON));

INSERT INTO @splits (y, x, level)
SELECT
    v.y, v.x, 1 AS level
FROM @vals AS v
WHERE
    v.y = 3;

DECLARE @level INT = 1;

WHILE 1=1
BEGIN;
    INSERT INTO @splits (y, x, level)
    SELECT
        v0.y,
        v0.x,
        @level + 1
    FROM @splits AS c
    CROSS APPLY
    (
        SELECT
            v_minus_one.y,
            v_minus_one.x,
            ROW_NUMBER() OVER (ORDER BY v_minus_one.y) AS r
        FROM @vals AS v_minus_one
        WHERE
            v_minus_one.x = c.x - 1
            AND v_minus_one.y > c.y

        UNION ALL

        SELECT
            v_plus_one.y,
            v_plus_one.x,
            ROW_NUMBER() OVER (ORDER BY v_plus_one.y) AS r
        FROM @vals AS v_plus_one
        WHERE
            v_plus_one.x = c.x + 1
            AND v_plus_one.y > c.y
    ) AS v0
    WHERE
        c.level = @level
        AND v0.r = 1

    IF @@ROWCOUNT = 0
        BREAK;

    SET @level += 1;
END;

SELECT
    COUNT(*)
FROM @splits;
