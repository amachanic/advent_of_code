/*
Part 1 involved a range search with a filter, and I was able to do it (with some preparation) in a
single non-recursive SQL query. For part 2, there were some repeating patterns, so I decided to
walk outward using a recursive CTE. This worked pretty well in this case! Both parts run sub-second.
*/


declare @n nvarchar(max) = N'............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............';


if object_id('tempdb..#rows') is not null
    drop table #rows;

select
    s.*,
    row_number() over (order by 1/0) as y
into #rows
from string_split(replace(@n, char(10), ''), char(13)) as s;

if object_id('tempdb..#map') is not null
    drop table #map;

declare @rowlen int = (select len(value) from #rows where y = 1);

with
a (n) as (select 1 union all select 1),
b (n) as (select x.n from a x, a y),
c (n) as (select x.n from b x, b y),
d (n) as (select x.n from c x, c y),
e (n) as (select x.n from d x, d y),
nums as
(
    select top(@rowlen)
        row_number() over (order by 1/0) as n
    from e
)
select
    nums.n as x,
    #rows.y,
    convert(char(1), substring(#rows.value, nums.n, 1)) collate Latin1_General_Bin2 as v
into #map
from nums, #rows

create clustered index antenna on #map (v, x, y);

declare @maxx int, @maxy int;
select @maxx = max(x), @maxy = max(y) from #map;


-- #1
select
    count(*)
from
(
    select distinct
        antinodes.*
    from
    (
        select
            m0.x as x1, m0.y as y1,
            m1.x as x2, m1.y as y2,
            abs(m0.x - m1.x) as xdiff,
            abs(m0.y - m1.y) as ydiff
        from #map as m0
        inner join #map as m1 on
            m1.v = m0.v
            and m1.x >= m0.x
            and (m1.x > m0.x or (m1.x = m0.x and m1.y > m0.y))
        where
            m0.v <> '.'
    ) as z
    cross apply
    (
        values
            (
                z.x1 - xdiff,
                case when z.y1 < z.y2 then z.y1 - ydiff else z.y1 + ydiff end
            ),
            (
                z.x2 + xdiff,
                case when z.y2 < z.y1 then z.y2 - ydiff else z.y2 + ydiff end
            )
    ) as antinodes (x,y)
    where
        antinodes.x between 1 and @maxx
        and antinodes.y between 1 and @maxy
) as z;


-- #2
with c as
(
    select
        antinodes.*
    from
    (
        select
            m0.x as x1, m0.y as y1,
            m1.x as x2, m1.y as y2,
            abs(m0.x - m1.x) as xdiff,
            abs(m0.y - m1.y) as ydiff
        from #map as m0
        inner join #map as m1 on
            m1.v = m0.v
            and m1.x >= m0.x
            and (m1.x > m0.x or (m1.x = m0.x and m1.y > m0.y))
        where
            m0.v <> '.'
    ) as z
    cross apply
    (
        values
            (
                x1,
                y1,
                0,
                0,
                1
            ),
            (
                x2,
                y2,
                0,
                0,
                1
            ),
            (
                z.x1 - xdiff,
                case when z.y1 < z.y2 then z.y1 - ydiff else z.y1 + ydiff end,
                -xdiff,
                case when z.y1 < z.y2 then -ydiff else ydiff end,
                0
            ),
            (
                z.x2 + xdiff,
                case when z.y2 < z.y1 then z.y2 - ydiff else z.y2 + ydiff end,
                xdiff,
                case when z.y2 < z.y1 then -ydiff else ydiff end,
                0
            )
    ) as antinodes (x, y, xdiff, ydiff, is_antenna)
    where
        antinodes.x between 1 and @maxx
        and antinodes.y between 1 and @maxy

    union all

    select
        x + xdiff,
        y + ydiff,
        xdiff,
        ydiff,
        0
    from c
    where
        (x + xdiff) between 1 and @maxx
        and (y + ydiff) between 1 and @maxy
        and c.is_antenna = 0
)
select
    count(*) 
from
(
    select distinct
        c.x, c.y
    from c
) as y;
