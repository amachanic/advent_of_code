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

DECLARE @splits TABLE (y INT, x INT, level INT, total BIGINT, is_split BIT, PRIMARY KEY (y, x));

INSERT INTO @splits (y, x, level, total, is_split)
SELECT
    v.y, v.x, 1 AS level, 1 AS total, 1 AS is_split
FROM @vals AS v
WHERE
    v.y = 3;

DECLARE @level INT = 1, @max_level INT = (SELECT COUNT(DISTINCT y) FROM @vals);

WHILE @level <= @max_level
BEGIN;
    INSERT INTO @splits
    SELECT
        s.y + 2 AS y,
        x0.next_x AS x,
        @level + 1 AS level,
        SUM(s.total) AS total,
        ISNULL
        (
            (
                SELECT
                    1
                FROM @vals AS v
                WHERE
                    v.x = x0.next_x
                    AND v.y = s.y + 2
            ),
            0
        ) AS is_split
    FROM @splits AS s
    CROSS APPLY
    (
        SELECT
            s.x
        WHERE
            s.is_split = 0

        UNION ALL

        SELECT
            s.x - 1
        WHERE
            s.is_split = 1

        UNION ALL

        SELECT
            s.x + 1
        WHERE
            s.is_split = 1
    ) AS x0 (next_x)
    WHERE
        s.level = @level
    GROUP BY
        s.y + 2,
        x0.next_x

    SET @level += 1;
END;

SELECT
    SUM(total)
FROM @splits
WHERE
    level = @max_level + 1;
