DECLARE @n VARCHAR(MAX) = N'123 328  51 64 
 45 64  387 23 
  6 98  215 314
*   +   *   +  '

SELECT
    SUM(x.final)
FROM
(
    SELECT
        CASE MIN(z3.func) WHEN '+' THEN SUM(z3.num) ELSE EXP(SUM(LOG(z3.num))) END AS final
    FROM
    (
        SELECT
            z2.full_grp,
            CONVERT(BIGINT, TRIM(TRANSLATE(z2.nums, '+*', '  '))) AS num,
            RIGHT(FIRST_VALUE(z2.nums) OVER (PARTITION BY z2.full_grp ORDER BY z2.pos), 1) AS func
        FROM
        (
            SELECT
                z1.full_grp,
                z1.pos,
                STRING_AGG(z1.v, '') WITHIN GROUP (ORDER BY z1.line) AS nums
            FROM
            (
                SELECT
                    z.*,
                    MAX(CASE WHEN r = 1 THEN grp ELSE NULL END) OVER (PARTITION BY pos) AS full_grp
                FROM
                (
                    SELECT
                        *,
                        SUM(CASE WHEN y.r = 1 AND x.v <> ' ' THEN 1 ELSE 0 END) OVER (ORDER BY y.r, x.pos) AS grp
                    FROM
                    (
                        SELECT
                            s.value,
                            s.ordinal AS line,
                            ROW_NUMBER() OVER (ORDER BY s.ordinal DESC) AS r
                        FROM STRING_SPLIT(REPLACE(@n, CHAR(13), ''), CHAR(10), 1) AS s
                    ) AS y
                    CROSS APPLY
                    (
                        SELECT
                            SUBSTRING(y.value, g.value, 1) AS v,
                            g.value AS pos
                        FROM GENERATE_SERIES(1, CONVERT(INT, DATALENGTH(y.value))) AS g
                    ) AS x
                ) AS z
            ) AS z1
            GROUP BY
                z1.full_grp,
                z1.pos
        ) AS z2
        WHERE
            z2.nums <> ''
    ) AS z3
    GROUP BY
        z3.full_grp
) AS x;
