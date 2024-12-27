/*
Today's puzzle required finding the shortest path among several options -- another BFS-oriented problem.

I decided to solve this by walking from the end back to the start, recording the shortest path to the
end from each cell. Sort of a DP-oriented approach, if I had the tools in SQL to do a DP-oriented
approach...

I tried implementing my solution using a recursive CTE but its performance was abysmal due to the fact
that I couldn't efficiently cut off previously-visited paths. So instead I went with a WHILE loop.
*/

declare @n nvarchar(max) = N'###############
#.......#....E#
#.#.###.#.###.#
#.....#.#...#.#
#.###.#####.#.#
#.#.#.......#.#
#.#.#####.###.#
#...........#.#
###.#.#####.#.#
#...#.....#.#.#
#.#.#.###.#.#.#
#.....#...#.#.#
#.###.#.#.#.#.#
#S..#.....#...#
###############';

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
    convert(int, 1) as move,
    convert(int, 1) as score,
    x.nextrow as row,
    x.nextcol as col,
    x.dir
into #moves
from #maze
cross apply
(
    select row, col-1, 'left' where has_left = 1
    union all
    select row, col+1, 'right' where has_right = 1
    union all
    select row-1, col, 'up' where has_up = 1
    union all
    select row+1, col, 'down' where has_down = 1
) as x (nextrow, nextcol, dir)
where
    cell = 'E';

create clustered index m on #moves (move);
create index rc on #moves (row, col, score);

declare @move int = 1;

while 1=1
begin
    insert into #moves
    select
        @move + 1,
        y.score,
        y.row,
        y.col,
        y.dir
    from
    (
        select
            x.dir,
            x.nextrow as row,
            x.nextcol as col,
            m.score + 1 + case when m.dir = x.dir then 0 else 1000 end as score
        from #moves as m
        inner join #maze as mz with (forceseek) on
            mz.row = m.row
            and mz.col = m.col
        cross apply
        (
            select m.row, m.col-1, 'left' where mz.has_left = 1
            union all
            select m.row, m.col+1, 'right' where mz.has_right = 1
            union all
            select m.row-1, m.col, 'up' where mz.has_up = 1
            union all
            select m.row+1, m.col, 'down' where mz.has_down = 1
        ) as x (nextrow, nextcol, dir)
        where
            m.move = @move
    ) as y
    where
        not exists (select * from #moves as m1 with (forceseek) where m1.row = y.row and m1.col = y.col and m1.score <= y.score);

    if @@rowcount = 0
        break;

    set @move += 1;
end;

select
    min(case m.dir when 'left' then m.score else m.score+1000 end)
from #moves as m
inner join #maze as mz on
    mz.cell = 'S'
    and mz.row = m.row
    and mz.col = m.col
;

