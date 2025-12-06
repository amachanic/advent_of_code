DECLARE @n NVARCHAR(MAX) = N'123 328  51 64 
 45 64  387 23 
  6 98     215 314
*   +   *   +  ';

SELECT
    SUM(x.final)
FROM
(
    SELECT
        CASE MIN(rows.func) WHEN '+' THEN SUM(CONVERT(BIGINT, rows.value)) ELSE EXP(SUM(LOG(CONVERT(BIGINT, rows.value)))) END AS final
    FROM
    (
        SELECT
            s1.value,
            s1.row,
            lines.line,
            LAST_VALUE(s1.value) OVER (PARTITION BY row ORDER BY line ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS func
        FROM
        (
            SELECT
                TRIM(s.value) AS val,
                ROW_NUMBER() OVER (ORDER BY 1/0) AS line
            FROM STRING_SPLIT
            (
                REPLACE(REPLACE(REPLACE(REPLACE(@n, CHAR(13), ''), '  ', ' '), '  ', ' '), '  ', ' '),
                CHAR(10)
            ) AS s
        ) AS lines
        CROSS APPLY
        (
            SELECT
                s10.value,
                ROW_NUMBER() OVER (ORDER BY 1/0) AS row
            FROM STRING_SPLIT(lines.val, ' ') AS s10
        ) AS s1
    ) AS rows
    WHERE
        rows.value <> rows.func
    GROUP BY
        rows.row
) AS x;
