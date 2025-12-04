DECLARE @n NVARCHAR(MAX) = N'..@@.@@@@.
@@@.@.@.@@
@@@@@.@.@@
@.@@@@..@.
@@.@@@@.@@
.@@@@@@@.@
.@.@.@.@@@
@.@@@.@@@@
.@@@@@@@@.
@.@.@@@.@.';

SELECT
    COUNT(*)
FROM
(
    SELECT
        ylines.y,
        xpos.x,
        xpos.thing,
        xpos.adj_rolls +
            LAG(xpos.adj_rolls, 1, 0) OVER (PARTITION BY xpos.x ORDER BY ylines.y) +
            LEAD(xpos.adj_rolls, 1, 0) OVER (PARTITION BY xpos.x ORDER BY ylines.y) - 1 AS total_adj
    FROM
    (
        SELECT
            ROW_NUMBER() OVER (ORDER BY 1/0) AS y,
            REPLACE(s.value, CHAR(13), '') AS line
        FROM STRING_SPLIT(@n, CHAR(10)) AS s
    ) AS ylines
    CROSS APPLY
    (
        SELECT
            x0.x,
            x0.thing,
            CASE x0.thing WHEN '@' THEN 1 ELSE 0 END +
                CASE LAG(x0.thing) OVER (ORDER BY x0.x) WHEN '@' THEN 1 ELSE 0 END +
                CASE LEAD(x0.thing) OVER (ORDER BY x0.x) WHEN '@' THEN 1 ELSE 0 END AS adj_rolls
        FROM
        (
            SELECT
                g.value AS x,
                SUBSTRING(ylines.line, g.value, 1) AS thing
            FROM GENERATE_SERIES(1, CONVERT(INT, LEN(ylines.line))) AS g
        ) AS x0
    ) AS xpos
) AS xy
WHERE
    xy.thing = '@'
    AND xy.total_adj < 4;
