DECLARE @n NVARCHAR(MAX) = N'3-5
10-14
16-20
16-20
12-18

1
5
8
11
17
32';

SELECT
    SUM(fin.e - fin.s + 1)
FROM
(
    SELECT
        MIN(final_groups.val) AS s,
        MAX(final_groups.val) As e
    FROM
    (
        SELECT
            row_sums.*,
            COALESCE
            (
                SUM
                (
                    CASE
                        WHEN row_sums.rs = 0 THEN 1
                        ELSE 0
                    END
                ) 
                    OVER
                    (
                        ORDER BY row_sums.val, row_sums.start_end DESC
                        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                    ),
                0
            ) AS grp
        FROM
        (
            SELECT
                y.val,
                y.start_end,
                SUM(start_end) OVER (ORDER BY y.val, y.start_end DESC ROWS UNBOUNDED PRECEDING) AS rs
            FROM
            (
                SELECT
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
        ) AS row_sums
    ) AS final_groups
    GROUP BY
        final_groups.grp
) AS fin;

