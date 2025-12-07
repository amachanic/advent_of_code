DECLARE @n VARCHAR(MAX) = N'123 328  51 64 
 45 64  387 23 
  6 98  215 314
*   +   *   +  '

SELECT
    SUM(x.final)
FROM
(
    SELECT
        CASE MIN(all_info.func) WHEN '+' THEN SUM(all_info.num) ELSE EXP(SUM(LOG(all_info.num))) END AS final
    FROM
    (
        SELECT
            full_nums.full_grp,
            CONVERT(BIGINT, TRIM(TRANSLATE(full_nums.nums, '+*', '  '))) AS num,
            RIGHT(FIRST_VALUE(full_nums.nums) OVER (PARTITION BY full_nums.full_grp ORDER BY full_nums.pos), 1) AS func
        FROM
        (
            SELECT
                groups.full_grp,
                groups.pos,
                STRING_AGG(groups.v, '') WITHIN GROUP (ORDER BY groups.line) AS nums
            FROM
            (
                SELECT
                    partial_groups.*,
                    MAX(CASE WHEN partial_groups.r = 1 THEN partial_groups.grp ELSE NULL END) OVER (PARTITION BY partial_groups.pos) AS full_grp
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
                ) AS partial_groups
            ) AS groups
            GROUP BY
                groups.full_grp,
                groups.pos
        ) AS full_nums
        WHERE
            full_nums.nums <> ''
    ) AS all_info
    GROUP BY
        all_info.full_grp
) AS x;
