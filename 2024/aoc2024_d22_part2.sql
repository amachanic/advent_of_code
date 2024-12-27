/*
;-(

My single SQL statement joy was short lived.

This was not especially difficult but took me way to long since I didn't understand the requirements,
which were to consider only the first time a given sequence of changes appeared. I instead initially
wrote code that found the best price across all instances of each sequence.

Note to self: READ CAREFULLY NEXT TIME.
*/

declare @n nvarchar(max) = N'1
2
3
2024';

if object_id('tempdb..#changes') is not null
    drop table #changes;

with c as
(
    select
        convert(varchar(50), s.value) as initial,
        convert(bigint, s.value) as s,
        convert(bigint, null) as prior,
        convert(int, 0) as i
    from string_split(replace(@n, char(10), ''), char(13)) as s

    union all

    select
        c.initial,
        (d2.s ^ (d2.s * 2048)) % 16777216,
        c.s,
        i + 1
    from c
    cross apply
    (
        values ((c.s ^ (c.s * 64)) % 16777216)
    ) as d1 (s)
    cross apply
    (
        values ((d1.s ^ (d1.s / 32)) % 16777216)
    ) as d2 (s)
    where
        i < 2000
)
select
    c.initial,
    c.i,
    c.s,
    convert(int, right(convert(varchar, c.s), 1)) as num,
    convert(int, right(convert(varchar, c.s), 1)) - convert(int, right(convert(varchar, c.prior), 1)) as delta
into #changes
from c
option (maxrecursion 0);

create clustered index ic on #changes (initial, i);

if object_id('tempdb..#deltas') is not null
    drop table #deltas;

select
    c.initial,
    c.i,
    c.delta as d1, c1.delta as d2, c2.delta as d3, c3.delta as d4,
    c3.num
into #deltas
from #changes as c
inner join #changes as c1 on c1.initial = c.initial and c1.i = c.i + 1
inner join #changes as c2 on c2.initial = c.initial and c2.i = c.i + 2
inner join #changes as c3 on c3.initial = c.initial and c3.i = c.i + 3
where
    c.i > 0;

create clustered index x on #deltas (d1,d2,d3,d4);

select top(1)
    *
from 
(
    select distinct
        d1,d2,d3,d4
    from #deltas
) as d
cross apply
(
    select
        sum(n) as s
    from
    (
        select
            num as n,
            row_number() over (partition by initial order by i) as r
        from #deltas as x0
        where
            x0.d1 = d.d1
            and x0.d2 = d.d2
            and x0.d3 = d.d3
            and x0.d4 = d.d4
    ) as x1
    where x1.r = 1
) as x
order by
    s desc;
