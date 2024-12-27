/*
This day's puzzles were an obvious fit for a BFS (in my humble opinion). I used a recursive CTE,
which was plenty fast enough here.
*/


declare @n nvarchar(max) = N'89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732';

if object_id('tempdb..#rows') is not null
    drop table #rows;

select
    s.value as cols,
    row_number() over (order by 1/0) as row
into #rows
from string_split(replace(@n, char(13), ''), char(10)) as s;

if object_id('tempdb..#cells') is not null
    drop table #cells;

declare @rowlen int = (select len(cols) from #rows where row = 1);

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
    #rows.row,
    nums.n as col,
    convert(int, substring(#rows.cols, nums.n, 1)) as c
into #cells
from #rows, nums
;

create clustered index xx on #cells (row, col);


-- #1
with rec as
(
    select
        row as startr,
        col as startc,
        row as lastr,
        col as lastc,
        c
    from #cells
    where
        c = 0

    union all

    select
        rec.startr,
        rec.startc,
        c.row,
        c.col,
        c.c
    from rec
    cross apply
    (
        values
            --up
            (rec.lastr - 1, rec.lastc),
            --down
            (rec.lastr + 1, rec.lastc),
            --left
            (rec.lastr, rec.lastc - 1),
            --right
            (rec.lastr, rec.lastc + 1)
    ) as x (nextrow, nextcol)
    inner join #cells as c on
        c.col = x.nextcol
        and c.row = x.nextrow
        and c.c = rec.c + 1
)
select
    count(*)
from
(
    select distinct
        startr, startc, lastr, lastc
    from rec
    where
        c = 9
) as x;


-- #2
with rec as
(
    select
        row as startr,
        col as startc,
        row as lastr,
        col as lastc,
        c
    from #cells
    where
        c = 0

    union all

    select
        rec.startr,
        rec.startc,
        c.row,
        c.col,
        c.c
    from rec
    cross apply
    (
        values
            --up
            (rec.lastr - 1, rec.lastc),
            --down
            (rec.lastr + 1, rec.lastc),
            --left
            (rec.lastr, rec.lastc - 1),
            --right
            (rec.lastr, rec.lastc + 1)
    ) as x (nextrow, nextcol)
    inner join #cells as c on
        c.col = x.nextcol
        and c.row = x.nextrow
        and c.c = rec.c + 1
)
select
    count(*)
from rec
where
    c = 9;
