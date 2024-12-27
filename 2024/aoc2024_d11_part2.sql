/*
This one took some serious thought. Massive, massive numbers involved, and the recursive CTE
from Part 1 didn't stand a chance. Were I solving this in Python I'd reach for some form of
memoized recursion, but this being SQL I instead used a temp table and aggregation at each phase.
Interestingly, my solution here for theh much bigger Part 2 is far faster than my solution for
Part 1. (Which shows just how bad recursive CTEs often are.)
*/

declare @n nvarchar(max) = N'125 17';

declare @max_blink int = 75;

if object_id('tempdb..#lvl') is not null
    drop table #lvl;

select
    0 as blink_count,
    convert(bigint, s.value) as v,
    count_big(*) as stone_count
into #lvl
from string_split(@n, ' ') as s
group by
    convert(bigint, s.value);

create clustered index b on #lvl (blink_count);

declare @i int = 0;

while @i < @max_blink
begin
    insert into #lvl
    select
        @i + 1,
        x.v,
        sum(stone_count)
    from #lvl
    cross apply
    (
        select
            case
                when v = 0 then 1
                when len(convert(varchar, v)) % 2 = 0 then convert(bigint, left(convert(varchar, v), len(convert(varchar, v)) / 2))
                else v * 2024
            end

        union all
        
        select
            convert(bigint, right(convert(varchar, v), len(convert(varchar, v)) / 2))
        where
            len(convert(varchar, v)) % 2 = 0
    ) as x (v)
    where
        blink_count = @i
    group by
        x.v;

    set @i = @i + 1;
end;

select sum(stone_count) from #lvl where blink_count = @max_blink;

