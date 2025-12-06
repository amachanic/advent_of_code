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
            group_starts.*,
            SUM(group_starts.grpstart) OVER (ORDER BY group_starts.val) AS grp
        FROM
        (
            SELECT
                row_sums.*,
                CASE WHEN LAG(row_sums.rs, 1, 0) OVER (ORDER BY row_sums.val, row_sums.start_end DESC) = 0 THEN 1 ELSE 0 END AS grpstart
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
        ) AS group_starts
    ) AS final_groups
    GROUP BY
        final_groups.grp
) AS fin;
