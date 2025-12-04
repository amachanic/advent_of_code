/*
A little bit brute but fast enough for today.
*/

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

DECLARE @rolls TABLE (x INT, y INT, thing CHAR(1), adj_rolls INT, PRIMARY KEY (x, y));

INSERT INTO @rolls (x, y, thing, adj_rolls)
SELECT
    xpos.x,
    ylines.y,
    xpos.thing,
    xpos.adj_rolls
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
) AS xpos;

DECLARE @removed TABLE (r char(1));

WHILE 1=1
BEGIN;
    INSERT INTO @removed
    SELECT u.t_old
    FROM
    (
        UPDATE r
        SET
            r.adj_rolls -= a0.sub,
            r.thing = CASE WHEN a0.thing = '@' THEN '' ELSE r.thing END
        OUTPUT
            inserted.thing AS t_new, deleted.thing AS t_old
        FROM @rolls AS r
        INNER JOIN
        (
            SELECT
                a.x,
                a.y,
                MAX(a.thing) AS thing,
                SUM(a.sub) AS sub
            FROM
            (
                SELECT
                    r0.x,
                    r0.y,
                    CASE WHEN r0.x - 1 = LAG(r0.x) OVER (PARTITION BY r0.y ORDER BY r0.x) THEN 1 ELSE 0 END AS rm_lft,
                    CASE WHEN r0.x + 1 = LEAD(r0.x) OVER (PARTITION BY r0.y ORDER BY r0.x) THEN 1 ELSE 0 END AS rm_rgt
                FROM
                (
                    SELECT
                        r.x,
                        r.y,
                        r.thing,
                        r.adj_rolls +
                            LAG(r.adj_rolls, 1, 0) OVER (PARTITION BY r.x ORDER BY r.y) +
                            LEAD(r.adj_rolls, 1, 0) OVER (PARTITION BY r.x ORDER BY r.y) - 1 AS total_adj
                    FROM @rolls as r
                ) AS r0
                WHERE
                    r0.thing = '@'
                    AND r0.total_adj < 4
            ) AS r1
            CROSS APPLY
            (
                SELECT
                    r1.x, r1.y, 1 + r1.rm_lft + r1.rm_rgt, '@'

                UNION ALL

                SELECT
                    r1.x - 1, r1.y, 1, ''
                WHERE
                    r1.rm_lft = 0

                UNION ALL

                SELECT
                    r1.x + 1, r1.y, 1, ''
                WHERE
                    r1.rm_rgt = 0
            ) AS a (x, y, sub, thing)
            GROUP BY
                a.x,
                a.y
        ) AS a0 ON
            a0.x = r.x
            AND a0.y = r.y
    ) AS u
    WHERE
        u.t_old = '@'
        AND u.t_new = '';

    IF @@ROWCOUNT = 0
        BREAK;
END;

SELECT
    COUNT(*)
FROM @removed;
