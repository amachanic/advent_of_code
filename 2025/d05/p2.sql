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

SELECT
    SUM(z3.e - z3.s + 1)
FROM
(
    SELECT
        MIN(z2.val) AS s,
        MAX(z2.val) As e
    FROM
    (
        SELECT
            z1.*,
            SUM(z1.grpstart) OVER (ORDER BY z1.val) AS grp
        FROM
        (
            SELECT
                z.*,
                CASE WHEN LAG(z.rs, 1, 0) OVER (ORDER BY z.val) = 0 THEN 1 ELSE 0 END AS grpstart
            FROM
            (
                SELECT DISTINCT
                    y.val,
                    SUM(start_end) OVER (ORDER BY y.val) AS rs
                FROM
                (
                    SELECT DISTINCT
                        CONVERT(BIGINT, LEFT(s.value, CHARINDEX('-', s.value) - 1)) AS s,
                        CONVERT(BIGINT, REPLACE(RIGHT(s.value, LEN(s.value) - CHARINDEX('-', s.value)), CHAR(13), '')) AS e
                    FROM STRING_SPLIT(@n, CHAR(10)) AS s
                    WHERE
                        s.value LIKE '%-%'
                ) AS x
                CROSS APPLY
                (
                    VALUES
                        (x.s, 1),
                        (x.e, -1)
                ) AS y (val, start_end)
            ) AS z
        ) AS z1
    ) AS z2
    GROUP BY
        z2.grp
) AS z3;
