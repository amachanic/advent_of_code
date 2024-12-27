/*
This uses the same initial walk as set up in Part 1, but I modified the final analysis a bit to
use a radius-based search, rather than explicitly looking in each direction.
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

declare @test_threshold int = 76;

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
create index rc on #moves (row, col, move);

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
    count(*)
from #moves as m
inner join #moves as m1 on
    m1.row between m.row - 20 and m.row + 20
    and m1.col between m.col - 20 and m.col + 20
    and abs(m.row - m1.row) + abs(m.col - m1.col) <= 20
where
    (m1.move - m.move - abs(m.row - m1.row) - abs(m.col - m1.col)) >= @test_threshold;
