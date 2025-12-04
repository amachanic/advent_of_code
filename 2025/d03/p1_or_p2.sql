/*
SQL Server linear-ish time solution

Uses a right-to-left scan on battery number (referred to as "slot" in the code) rather than left-to-right
like the Python solutions.
*/

DECLARE @n NVARCHAR(MAX) = N'987654321111111
811111111111119
234234234234278
818181911112111';

-- How many batteries do we need?
DECLARE @k INT = 12;

DECLARE @lines TABLE (lineid INT IDENTITY(1,1), line VARCHAR(MAX));
INSERT INTO @lines (line)
SELECT
    REPLACE(value, char(13), '') AS v
FROM STRING_SPLIT(@n, CHAR(10)) AS s;

DECLARE @nums TABLE 
(
    pos INT, 
    lineid INT, 
    num CHAR(1),
    PRIMARY KEY (lineid, pos, num)
);
INSERT INTO @nums
(
    pos,
    lineid,
    num
)
SELECT
    x.pos,
    l.lineid,
    x.num
FROM @lines AS l
CROSS APPLY
(
    SELECT
        g.value AS pos,
        SUBSTRING(line, CONVERT(INT, g.value), 1) AS num
    FROM GENERATE_SERIES(1, CONVERT(INT, LEN(l.line))) AS g
) AS x;

WITH
best AS
(
    SELECT
        1 AS slot,
        n.pos,
        n.lineid,
        n.num
    FROM @lines AS l
    CROSS APPLY
    (
        SELECT TOP(1)
            n0.*
        FROM @nums AS n0
        CROSS APPLY (VALUES (LEN(l.line) - (@k - 1))) AS e (endpos)
        WHERE
            n0.lineid = l.lineid
            AND n0.pos BETWEEN 1 AND e.endpos
        ORDER BY
            n0.num DESC,
            n0.pos
    ) AS n

    UNION ALL

    SELECT
        b.slot + 1,
        n.pos,
        n.lineid,
        n.num
    FROM best AS b
    INNER JOIN @lines AS l ON
        l.lineid = b.lineid
    CROSS APPLY
    (
        SELECT
            n0.*,
            ROW_NUMBER() OVER
            (
                ORDER BY
                    n0.num DESC,
                    n0.pos
            ) AS r
        FROM @nums AS n0
        CROSS APPLY (VALUES (LEN(l.line) - (@k - (b.slot + 1)))) AS e (endpos)
        WHERE
            n0.lineid = l.lineid
            AND n0.pos BETWEEN b.pos + 1 AND e.endpos
    ) AS n
    WHERE
        b.slot < @k
        AND n.r = 1
)
SELECT
    SUM(CONVERT(BIGINT, final.joltage))
FROM
(
    SELECT
        STRING_AGG(b1.num, '') WITHIN GROUP (ORDER BY b1.slot) AS joltage
    FROM best AS b1
    GROUP BY
        b1.lineid
) AS final;
