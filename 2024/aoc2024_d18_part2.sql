/*
I decided to just brute force this one. I added an outer loop on the first part, started at one byte
after the prior challenge's byte (since I knew that that one was still good), and just ran everything
forward from there until it failed. Plenty fast enough.
*/

declare @n nvarchar(max) = N'5,4
4,2
4,5
3,0
2,1
6,3
2,4
1,5
0,6
3,3
2,6
5,1
1,2
5,5
2,5
6,5
1,4
0,4
6,4
1,1
6,1
1,0
0,5
1,6
2,0';

declare @minbyte int = 13, @maxbyte int = (select count(*) from string_split(@n, char(10)));

while @minbyte < @maxbyte
begin
    declare @maxy int = 6, @maxx int = 6, @num_bytes int = @minbyte + (@maxbyte - @minbyte)/2;

    print(concat('min: ', @minbyte, ' - max: ', @maxbyte, ' - num: ', @num_bytes));

    if object_id('tempdb..#grid') is not null
        drop table #grid;

    with
    a (n) as (select 1 union all select 1),
    b (n) as (select x.n from a x, a y),
    c (n) as (select x.n from b x, b y),
    d (n) as (select x.n from c x, c y)
    select
        grid.*,
        case when cell in ('.', 'S', 'E') and lag(cell) over (partition by row order by col) in ('.', 'S', 'E') then 1 else 0 end as has_left,
        case when cell in ('.', 'S', 'E') and lead(cell) over (partition by row order by col) in ('.', 'S', 'E') then 1 else 0 end as has_right,
        case when cell in ('.', 'S', 'E') and lag(cell) over (partition by col order by row) in ('.', 'S', 'E') then 1 else 0 end as has_up,
        case when cell in ('.', 'S', 'E') and lead(cell) over (partition by col order by row) in ('.', 'S', 'E') then 1 else 0 end as has_down
    into #grid
    from
    (
        select
            cells.row,
            cells.col,
            case when bytes.x is not null then '#' else cells.cell end as cell    
        from
        (
            select
                ynum.row,
                xnum.col,
                case when row=0 and col=0 then 'S' when row=@maxy and col=@maxx then 'E' else '.' end as cell
            from
            (
                select top(@maxy+1)
                    row_number() over (order by 1/0) - 1 as row
                from d
            ) as ynum
            cross join
            (
                select top(@maxx+1)
                    row_number() over (order by 1/0) - 1 as col
                from d
            ) as xnum
        ) as cells
        left outer join
        (
            select
                convert(int, left(s.value, charindex(',', s.value) - 1)) as x,
                convert(int, substring(s.value, charindex(',', s.value) + 1, len(s.value))) as y,
                row_number() over (order by 1/0) as byte_num
            from string_split(replace(@n, char(10), ''), char(13)) as s
        ) as bytes on
            bytes.x = cells.col
            and bytes.y = cells.row
            and bytes.byte_num <= @num_bytes
    ) as grid;

    create unique clustered index mz on #grid (row, col);

    if object_id('tempdb..#moves') is not null
        drop table #moves;

    select
        identity(int, 1, 1) as move,
        convert(int, 1) as score,
        x.nextrow as row,
        x.nextcol as col,
        x.dir
    into #moves
    from #grid
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

    set nocount on;

    --continue duplicate walks if they're cheaper than a prior walk that hit the same point (from the same direction)
    while 1=1
    begin
        declare @score int, @dir varchar(20), @row int, @col int, @path varchar(max);

        select
            @score = score,
            @dir = dir,
            @row = row,
            @col = col
        from #moves
        where move = @move;

        if @@rowcount = 0
            break;

        insert into #moves (score, row, col, dir)
        select
            @score + 1,
            y.row,
            y.col,
            y.dir
        from
        (
            select
                x.dir,
                x.nextrow as row,
                x.nextcol as col
            from #grid as mz
            cross apply
            (
                select @row, @col-1, 'left' where mz.has_left = 1
                union all
                select @row, @col+1, 'right' where mz.has_right = 1
                union all
                select @row-1, @col, 'up' where mz.has_up = 1
                union all
                select @row+1, @col, 'down' where mz.has_down = 1
            ) as x (nextrow, nextcol, dir)
            where
                mz.row = @row
                and mz.col = @col
        ) as y
        where
            not exists (select * from #moves as m1 with (forceseek) where m1.row = y.row and m1.col = y.col and m1.score <= (@score + 1))

        set @move += 1;
    end;

    if not exists (select * from #moves as m where m.row = 0 and m.col = 0)
    begin
        set @maxbyte = @num_bytes;
    end;
    else
    begin
        set @minbyte = @num_bytes + 1;
    end;
end;

select
    value,
    @maxbyte as first_bad_byte
from
(
    select
        value,
        row_number() over (order by 1/0) as byte_num
    from string_split(replace(@n, char(10), ''), char(13)) as s
) as n
where
    n.byte_num = @maxbyte;
