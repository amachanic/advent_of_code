DECLARE @n VARCHAR(MAX) = '7,1
11,1
11,7
9,7
9,5
2,5
2,3
7,3';

WITH
n AS
(
    SELECT
        CONVERT(BIGINT, LEFT(s.value, CHARINDEX(',', s.value) - 1)) AS x,
        CONVERT(BIGINT, RIGHT(s.value, LEN(s.value) - CHARINDEX(',', s.value))) AS y
    FROM STRING_SPLIT(REPLACE(@n, CHAR(13), ''), CHAR(10)) AS s
)
SELECT TOP(1)
    (ABS(n1.x - n0.x) + 1) * (ABS(n1.y - n0.y) + 1) AS dist
FROM n AS n0
CROSS JOIN n AS n1
ORDER BY
    dist DESC;
