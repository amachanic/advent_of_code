/*
Another 2D maze!

I started this one by copying code from Day 18, within 10 minutes I had the sample input working
properly...and then I spent the better part of an hour trying to figure out why the full input 
wouldn't work. Turns out the sample doesn't have any paths that save 100 picoseconds (see the
@test_threshold variable), and had accidentally used > rather than >= in the final query. And
this is my reminder that the two most difficult problems in CS are naming, cache invalidation,
and off-by-one errors.
*/


declare @n nvarchar(max) = N'###############
#...#...#.....#
#.#.#.#.#.###.#
#S#...#.#.#...#
#######.#.#.###
#######.#.#...#
#######.#.###.#
###..E#...#...#
###.#######.###
#...###...#...#
#.#####.#.###.#
#.#...#.#.#...#
#.#.#.#.#.#.###
#...#...#...###
###############';

declare @test_threshold int = 64;

if object_id('tempdb..#rows') is not null
    drop table #rows;

select
    s.value,
    row_number() over (order by 1/0) as row
into #rows
from string_split(replace(@n, char(10), ''), char(13)) as s;

if object_id('tempdb..#maze') is not null
    drop table #maze;

declare @rowlen int = (select len(value) from #rows where row = 1);

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
    x.*,
    case when cell in ('.', 'S', 'E') and lag(cell) over (partition by row order by col) in ('.', 'S', 'E') then 1 else 0 end as has_left,
    case when cell in ('.', 'S', 'E') and lead(cell) over (partition by row order by col) in ('.', 'S', 'E') then 1 else 0 end as has_right,
    case when cell in ('.', 'S', 'E') and lag(cell) over (partition by col order by row) in ('.', 'S', 'E') then 1 else 0 end as has_up,
    case when cell in ('.', 'S', 'E') and lead(cell) over (partition by col order by row) in ('.', 'S', 'E') then 1 else 0 end as has_down
into #maze
from
(
    select
        row,
        nums.n as col,
        substring(value, nums.n, 1) as cell
    from #rows, nums
) as x;

create unique clustered index mz on #maze (row, col);

if object_id('tempdb..#moves') is not null
    drop table #moves;

select
    identity(int, 0, 1) as move,
    row,
    col,
    convert(varchar(25), '') as dir
into #moves
from #maze
where
    cell = 'S';

create clustered index m on #moves (move);
create index rc on #moves (row, col);

declare @move int = 0;

set nocount off;

while 1=1
begin
    declare @dir varchar(20), @row int, @col int, @path varchar(max);

    select
        @dir = dir,
        @row = row,
        @col = col
    from #moves
    where move = @move;

    if @@rowcount = 0
        break;

    insert into #moves
    select
        y.row,
        y.col,
        y.dir
    from
    (
        select
            x.dir,
            x.nextrow as row,
            x.nextcol as col
        from #maze as mz with (forceseek)
        cross apply
        (
            select @row, @col-1, 'left' where mz.has_left = 1 and @dir <> 'right'
            union all
            select @row, @col+1, 'right' where mz.has_right = 1 and @dir <> 'left'
            union all
            select @row-1, @col, 'up' where mz.has_up = 1 and @dir <> 'down'
            union all
            select @row+1, @col, 'down' where mz.has_down = 1 and @dir <> 'up'
        ) as x (nextrow, nextcol, dir)
        where
            mz.row = @row
            and mz.col = @col
    ) as y;

    set @move += 1;
end;

select
    sum(c)
from
(
    select m1.move - m.move - 2 as savings, count(*) as c
    from #moves as m
    cross apply
    (
        select m_right.move from #moves as m_right where m_right.row = m.row + 2 and m_right.col = m.col
        union all
        select m_left.move from #moves as m_left where m_left.row = m.row - 2 and m_left.col = m.col
        union all
        select m_up.move from #moves as m_up where m_up.row = m.row and m_up.col = m.col - 2
        union all
        select m_down.move from #moves as m_down where m_down.row = m.row and m_down.col = m.col + 2
    ) as m1
    where
        m1.move - m.move > 2
    group by 
        m1.move - m.move - 2
) as x
where
    x.savings >= @test_threshold
;
