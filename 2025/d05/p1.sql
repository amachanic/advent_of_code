DECLARE @n NVARCHAR(MAX) = N'3-5
10-14
16-20
12-18

1
5
8
11
17
32';

DECLARE @ranges TABLE(s BIGINT, e BIGINT, PRIMARY KEY (s, e))
INSERT INTO @ranges (s, e)
SELECT DISTINCT
    CONVERT(BIGINT, LEFT(s.value, CHARINDEX('-', s.value) - 1)) AS s,
    CONVERT(BIGINT, REPLACE(RIGHT(s.value, LEN(s.value) - CHARINDEX('-', s.value)), CHAR(13), '')) AS e
FROM STRING_SPLIT(@n, CHAR(10)) AS s
WHERE
    s.value LIKE '%-%';

SELECT
    COUNT(*)
FROM STRING_SPLIT(@n, CHAR(10)) AS s
WHERE
    s.value NOT LIKE '%-%'
    AND LEN(s.value) > 1
    AND EXISTS
    (
        SELECT
            *
        FROM @ranges AS r
        WHERE
            CONVERT(BIGINT, REPLACE(s.value, CHAR(13), '')) BETWEEN r.s AND r.e
    );
