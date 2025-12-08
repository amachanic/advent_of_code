/*
Disclaimer: Not my best work :-)
*/

DECLARE @n VARCHAR(MAX) = '162,817,812
57,618,57
906,360,560
592,479,940
352,342,300
466,668,158
542,29,236
431,825,988
739,650,466
52,470,668
216,146,977
819,987,18
117,168,530
805,96,715
346,949,466
970,615,88
941,993,340
862,61,35
984,92,344
425,690,689';

DECLARE @target INT = 1000;

DECLARE @distances TABLE (raw1 VARCHAR(50), raw2 VARCHAR(50), dist FLOAT, id INT IDENTITY(1,1), PRIMARY KEY (id), UNIQUE (raw1, raw2));

WITH
points AS
(
    SELECT
        CONVERT(BIGINT, LEFT(s.value, CHARINDEX(',', s.value) - 1)) AS x,
        CONVERT(BIGINT, SUBSTRING(s.value, CHARINDEX(',', s.value) + 1, CHARINDEX(',', s.value, CHARINDEX(',', s.value) + 1) - (CHARINDEX(',', s.value) + 1))) AS y,
        CONVERT(BIGINT, REVERSE(LEFT(REVERSE(s.value), CHARINDEX(',', REVERSE(s.value)) - 1))) AS z,
        s.value AS raw
    FROM STRING_SPLIT(REPLACE(@n, CHAR(13), ''), CHAR(10)) AS s
)
INSERT INTO @distances (raw1, raw2, dist)
SELECT
    p1.raw,
    p2.raw,
    SQRT(POWER(p1.x - p2.x, 2) + POWER(p1.y - p2.y, 2) + POWER(p1.z - p2.z, 2)) AS dist
FROM points AS p1
INNER JOIN points AS p2 ON
    p1.x < p2.x
    OR (p1.x = p2.x AND p1.y < p2.y)
    OR (p1.x = p2.x AND p1.y = p2.y AND p1.z < p2.z)
ORDER BY
    dist;

DECLARE @groups TABLE (grp VARCHAR(50), raw VARCHAR(50), PRIMARY KEY (grp, raw) WITH (IGNORE_DUP_KEY=ON));

DECLARE @total INT = 0;

WHILE @total < @target
BEGIN;
    DECLARE @point1 VARCHAR(50), @point2 VARCHAR(50);
    SELECT
        @point1 = d.raw1,
        @point2 = d.raw2
    FROM @distances AS d
    WHERE
        d.id = @total + 1;

    SET @total += 1;

    DECLARE @point1grp VARCHAR(50) = NULL;
    SELECT TOP(1)
        @point1grp = g.grp
    FROM @groups AS g
    WHERE
        g.raw = @point1;
    
    DECLARE @point2grp VARCHAR(50) = NULL;
    SELECT TOP(1)
        @point2grp = g.grp
    FROM @groups AS g
    WHERE
        g.raw = @point2;
    
    IF @point1grp IS NOT NULL AND @point2grp IS NOT NULL
    BEGIN;
        IF @point1grp = @point2grp
        BEGIN;
            CONTINUE;
        END;
        ELSE
        BEGIN;
            DECLARE @finalgrp VARCHAR(50) = CASE WHEN @point1grp < @point2grp THEN @point1grp ELSE @point2grp END;
            SET @finalgrp = CASE WHEN @finalgrp < @point1 THEN @finalgrp ELSE @point1 END;
            SET @finalgrp = CASE WHEN @finalgrp < @point2 THEN @finalgrp ELSE @point2 END;

            INSERT INTO @groups
            SELECT
                @finalgrp, g.raw
            FROM @groups AS g
            WHERE
                g.grp IN (@finalgrp, @point1grp, @point2grp)
            UNION
            SELECT
                @finalgrp, @point1
            UNION
            SELECT
                @finalgrp, @point2;

            DELETE FROM @groups
            WHERE
                grp IN (@point1grp, @point2grp)
                AND grp <> @finalgrp;

            CONTINUE;
        END;
    END;

    IF @point1grp IS NOT NULL
    BEGIN;
        INSERT INTO @groups
        SELECT
            @point1grp,
            @point1
        UNION ALL
        SELECT
            @point1grp,
            @point2;

        CONTINUE;
    END;

    IF @point2grp IS NOT NULL
    BEGIN;
        INSERT INTO @groups
        SELECT
            @point2grp,
            @point1
        UNION ALL
        SELECT
            @point2grp,
            @point2;

        CONTINUE;
    END;

    INSERT INTO @groups (grp, raw)
    SELECT @point1, @point1
    UNION ALL
    SELECT @point1, @point2;
END;

SELECT
    EXP(SUM(LOG(grpcount)))
FROM
(
    SELECT DISTINCT TOP(3)
        grp, grpcount
    FROM
    (
        SELECT
            *, COUNT(*) OVER (PARTITION BY grp) AS grpcount
        FROM @groups
    ) AS x
    ORDER BY
        grpcount DESC
) AS y;
