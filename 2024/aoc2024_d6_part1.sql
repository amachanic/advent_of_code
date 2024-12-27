/*
This challenge required walking a step at a time, which I accomplished using a recursive CTE... not too difficult. (See Part 2.)
*/

declare @n nvarchar(max) = N'....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...'

if object_id('tempdb..#n') is not null
    drop table #n;

select
    value as cols,
    row_number() over (order by 1/0) as r
into #n
from string_split(replace(@n, char(10), ''), char(13));

create unique clustered index rr on #n (r);

declare 
    @startr int, 
    @startc int;

select
    @startc = charindex('^', cols),
    @startr = r
from #n
where
    cols like '%^%';

with
visits as
(
    select
        @startr as r,
        @startc as c,
        convert(varchar(5), 'up') as dir

    union all

    select
        case nextchar.p when '#' then v.r else nextpos.r end,
        case nextchar.p when '#' then v.c else nextpos.c end,
        case nextchar.p
            when '#' then convert(varchar(5), case v.dir when 'up' then 'right' when 'right' then 'down' when 'down' then 'left' when 'left' then 'up' end)
            else v.dir
        end        
    from visits as v
    cross apply
    (
        values
            (
                v.r + case dir when 'up' then -1 when 'down' then 1 else 0 end,
                v.c + case dir when 'right' then 1 when 'left' then -1 else 0 end
            )
    ) as nextpos(r, c)
    inner join #n as n on
        n.r = nextpos.r
    cross apply
    (
        values
            (
                substring
                (
                    n.cols,
                    nextpos.c,
                    1
                )
            )
    ) as nextchar (p)
    where
        nextchar.p <> ''
)
select distinct
    r, c
from visits
option(maxrecursion 0);

