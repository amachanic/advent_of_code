DECLARE @n VARCHAR(MAX) = '7,1
11,1
11,7
9,7
9,5
2,5
2,3
7,3';

DECLARE @p GEOMETRY = 
    (
        SELECT
            'POLYGON((' + STRING_AGG(REPLACE(s.value, ',', ' '), ', ') + '))'
        FROM
        (
            SELECT 
                s0.value
            FROM STRING_SPLIT(REPLACE(@n, CHAR(13), ''), CHAR(10)) AS s0

            UNION ALL

            SELECT TOP(1)
                s1.value
            FROM STRING_SPLIT(REPLACE(@n, CHAR(13), ''), CHAR(10)) AS s1
        ) AS s
    );

DECLARE @dists TABLE (x1 BIGINT, y1 BIGINT, x2 BIGINT, y2 BIGINT, dist BIGINT, i INT IDENTITY(1,1), PRIMARY KEY (i));

WITH
n AS
(
    SELECT
        CONVERT(BIGINT, LEFT(s.value, CHARINDEX(',', s.value) - 1)) AS x,
        CONVERT(BIGINT, RIGHT(s.value, LEN(s.value) - CHARINDEX(',', s.value))) AS y
    FROM STRING_SPLIT(REPLACE(@n, CHAR(13), ''), CHAR(10)) AS s
)
INSERT INTO @dists (x1, y1, x2, y2, dist)
SELECT
    n0.x, n0.y,
    n1.x, n1.y,
    (ABS(n1.x - n0.x) + 1) * (ABS(n1.y - n0.y) + 1) AS dist
FROM n AS n0
CROSS JOIN n AS n1
WHERE
    NOT (n0.x = n1.x AND n0.y = n1.y)
ORDER BY
    dist DESC;

DECLARE @i INT = 1;
WHILE 1=1
BEGIN;
    DECLARE @g GEOMETRY, @d BIGINT;

    SELECT
        @g = CONVERT(GEOMETRY, CONCAT('POLYGON((', x1, ' ', y1, ',', x1, ' ', y2, ',', x2, ' ', y2, ',', x2, ' ', y1, ',', x1, ' ', y1, '))')),
        @d = dist
    FROM @dists
    WHERE
        i = @i;

    IF @p.STContains(@g) = 1
    BEGIN;
        SELECT @d;

        BREAK;
    END;

    SET @i += 1;
END;
