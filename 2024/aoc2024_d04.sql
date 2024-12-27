/*
I decided to go with a couple of temp tables for this one, in the interest of reasonable performance.
*/

declare @n nvarchar(max) = N'MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX';

if object_id('tempdb..#x') is not null
    drop table #x;

create table #x (r nvarchar(max), rn int identity(1,1) not null primary key);

insert into #x (r)
select value 
from string_split(replace(@n, char(10), ''), char(13));

if object_id('tempdb..#nums') is not null
    drop table #nums;

declare @rowlen int = (select len(r) from #x where rn = 1);

with
a (n) as (select 1 union all select 1),
b (n) as (select x.n from a x, a y),
c (n) as (select x.n from b x, b y),
d (n) as (select x.n from c x, c y),
e (n) as (select x.n from d x, d y)
select top(@rowlen)
    row_number() over (order by 1/0) as n
into #nums
from e;

-- #1
with
x as
(
    select 
        #x.rn, nu.n
    from #x
    cross join #nums as nu
    where
        substring(#x.r, nu.n, 1) = 'X'
),
m as
(
    select
        nxt.n, nxt.rn, nxt.dir
    from x
    cross apply
    (
        values
            --up
            (x.rn - 1, x.n, 'up'),
            --down
            (x.rn + 1, x.n, 'down'),
            --left
            (x.rn, x.n - 1, 'left'),
            --right
            (x.rn, x.n + 1, 'right'),
            --up-left
            (x.rn - 1, x.n - 1, 'up-left'),
            --down-left
            (x.rn + 1, x.n - 1, 'down-left'),
            --up-right
            (x.rn - 1, x.n + 1, 'up-right'),
            --down-right
            (x.rn + 1, x.n + 1, 'down-right')
    ) as nxt (rn, n, dir)
    where
        exists
        (
            select
                *
            from #x as x0
            where
                x0.rn = nxt.rn
                and substring(x0.r, nxt.n, 1) = 'M'
        )
),
a as
(
    select
        nxt.n, nxt.rn, m.dir
    from m
    cross apply
    (
        select
            case m.dir
                when 'up' then m.rn - 1
                when 'down' then m.rn + 1
                when 'left' then m.rn
                when 'right' then m.rn
                when 'up-left' then m.rn - 1
                when 'down-left' then m.rn + 1
                when 'up-right' then m.rn - 1
                when 'down-right' then m.rn + 1
            end as rn,
            case m.dir
                when 'up' then m.n
                when 'down' then m.n
                when 'left' then m.n - 1
                when 'right' then m.n + 1
                when 'up-left' then m.n - 1
                when 'down-left' then m.n - 1
                when 'up-right' then m.n + 1
                when 'down-right' then m.n + 1
            end as n
    ) as nxt (rn, n)
    where
        exists
        (
            select
                *
            from #x as x0
            where
                x0.rn = nxt.rn
                and substring(x0.r, nxt.n, 1) = 'A'
        )
),
s as
(
    select
        nxt.n, nxt.rn
    from a
    cross apply
    (
        select
            case a.dir
                when 'up' then a.rn - 1
                when 'down' then a.rn + 1
                when 'left' then a.rn
                when 'right' then a.rn
                when 'up-left' then a.rn - 1
                when 'down-left' then a.rn + 1
                when 'up-right' then a.rn - 1
                when 'down-right' then a.rn + 1
            end as rn,
            case a.dir
                when 'up' then a.n
                when 'down' then a.n
                when 'left' then a.n - 1
                when 'right' then a.n + 1
                when 'up-left' then a.n - 1
                when 'down-left' then a.n - 1
                when 'up-right' then a.n + 1
                when 'down-right' then a.n + 1
            end as n
    ) as nxt (rn, n)
    where
        exists
        (
            select
                *
            from #x as x0
            where
                x0.rn = nxt.rn
                and substring(x0.r, nxt.n, 1) = 'S'
        )
)
select
    count(*)
from s;


-- #2
with
m as
(
    select 
        #x.rn, nu.n
    from #x
    cross join #nums as nu
    where
        substring(#x.r, nu.n, 1) = 'M'
),
a as
(
    select
        nxt.n, nxt.rn, nxt.dir
    from m
    cross apply
    (
        values
            --up-left
            (m.rn - 1, m.n - 1, 'up-left'),
            --down-left
            (m.rn + 1, m.n - 1, 'down-left'),
            --up-right
            (m.rn - 1, m.n + 1, 'up-right'),
            --down-right
            (m.rn + 1, m.n + 1, 'down-right')
    ) as nxt (rn, n, dir)
    where
        exists
        (
            select
                *
            from #x as x0
            where
                x0.rn = nxt.rn
                and substring(x0.r, nxt.n, 1) = 'A'
        )
),
s as
(
    select
        a.dir, a.n, a.rn
    from a
    cross apply
    (
        select
            case a.dir
                when 'up-left' then a.rn - 1
                when 'down-left' then a.rn + 1
                when 'up-right' then a.rn - 1
                when 'down-right' then a.rn + 1
            end as rn,
            case a.dir
                when 'up-left' then a.n - 1
                when 'down-left' then a.n - 1
                when 'up-right' then a.n + 1
                when 'down-right' then a.n + 1
            end as n
    ) as nxt (rn, n)
    where
        exists
        (
            select
                *
            from #x as x0
            where
                x0.rn = nxt.rn
                and substring(x0.r, nxt.n, 1) = 'S'
        )
)
select
    count(*)
from
(
    select distinct
        s0.n, s0.rn
    from s s0, s s1
    where
        s0.n = s1.n
        and s0.rn = s1.rn
        and s0.dir <> s1.dir
) as x;
