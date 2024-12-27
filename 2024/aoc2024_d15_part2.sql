/*
After Part 1, I didn't find this to be too difficult. The boxes are now all twice as big, laterally.
This means that lateral moves still work the same way, but up and down moves need to have slightly
more involved logic. I wound up using a recursive methodology to find all touching boxes, and move
them all in one go.
*/

declare @n nvarchar(max) = N'##########
#..O..O.O#
#......O.#
#.OO..O.O#
#..O@..O.#
#O#..O...#
#O..O..O.#
#.OO.O.OO#
#....O...#
##########

<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^'
;

if object_id('tempdb..#raw') is not null
    drop table #raw;

select
    s.value,
    row_number() over (order by 1/0) as r
into #raw
from string_split(replace(@n, char(10), ''), char(13)) as s;

update #raw
set value = replace(replace(replace(replace(value, '#', '##'), 'O', '[]'), '.', '..'), '@', '@.');

declare @separator int = (select r from #raw where value = '');
declare @width int = (select len(value) from #raw where r = 1);

if object_id('tempdb..#map') is not null
    drop table #map;

with
a (n) as (select 1 union all select 1),
b (n) as (select x.n from a x, a y),
c (n) as (select x.n from b x, b y),
d (n) as (select x.n from c x, c y),
nums as
(
    select top(@width)
        row_number() over (order by 1/0) as n
    from d
)
select
    r as row,
    nums.n as col,
    convert(char(1), SUBSTRING(#raw.value, nums.n, 1)) as cell
into #map
from #raw, nums
where r < @separator;

create index r on #map (row, col, cell);
create index c on #map (col, row, cell);
create index cell on #map (cell, col, row);

if object_id('tempdb..#moves') is not null
    drop table #moves;

with
c as
(
    select
        value,
        r,
        convert(int, 1) as pos,
        convert(char(1), substring(value, 1, 1)) as move
    from #raw
    where
        r > @separator

    union all

    select
        value,
        r,
        pos + 1,
        convert(char(1), substring(value, pos + 1, 1))
    from c
    where
        len(value) > pos
)
select
    row_number() over (order by r, pos) as move_num,
    move
into #moves
from c
option (maxrecursion 0);

declare @move_num int = 1;
declare @robot_row int, @robot_col int;
select @robot_row = row, @robot_col = col from #map where cell = '@';

declare @nearest_space int;
declare @next_cell char(1);

if object_id('tempdb..#boxes') is not null
    drop table #boxes;

create table #boxes
(
    obj char(1) not null,
    row int not null,
    col int not null,
    primary key (row, col)
);

set nocount on;

while 1=1
begin
    declare @move char(1) = (select move from #moves where move_num = @move_num);
    if @move is null
        break;

    --if not touching a box or wall, just move
    --if touching a box, recursively find all connected boxes; make sure there's no wall in play
    if @move = '^'
    begin
        select
            @next_cell = cell
        from #map
        where
            col = @robot_col
            and row = @robot_row - 1;

        if @next_cell <> '#'
        begin
            if @next_cell in ('[', ']')
            begin
                truncate table #boxes;
                with boxes as
                (
                    select
                        convert(char(1), '[') as obj,
                        @robot_row - 1 as row,
                        case @next_cell when '[' then @robot_col else @robot_col - 1 end as col

                    union all

                    select
                        convert(char(1), case m.cell when ']' then '[' else m.cell end),
                        convert(int, m.row),
                        convert(int, case m.cell when ']' then m.col - 1 else m.col end)
                    from boxes as b
                    inner join #map as m on
                        m.row = b.row - 1
                        and m.col between b.col and b.col + 1
                        and m.cell <> '.'
                    where
                        b.obj <> '#'
                        and not (m.col = b.col + 1 and m.cell = ']')
                )
                insert into #boxes
                select distinct
                    obj,row,col
                from boxes;

                if not exists (select * from #boxes where obj = '#')
                begin
                    update m
                    set
                        m.cell = ch0.new
                    from #map as m
                    inner join
                    (
                        select
                            ch.col,
                            ch.row,
                            max(ch.cell) as new
                        from #boxes as b
                        cross apply
                        (
                            values
                            (
                                b.col,
                                b.row,
                                '.'
                            ),
                            (
                                b.col+1,
                                b.row,
                                '.'
                            ),
                            (
                                b.col,
                                b.row-1,
                                '['
                            ),
                            (
                                b.col+1,
                                b.row-1,
                                ']'
                            )
                        ) as ch (col, row, cell)
                        group by
                            ch.col, ch.row
                    ) as ch0 on
                        ch0.col = m.col
                        and ch0.row = m.row;
                end;
            end;

            if @next_cell = '.' or not exists (select * from #boxes where obj = '#')
            begin
                update #map
                set cell = case row when @robot_row then '.' else '@' end
                where
                    col = @robot_col
                    and row between @robot_row - 1 and @robot_row;

                set @robot_row = @robot_row - 1;
            end;
        end;
    end;
    else if @move = 'v'
    begin
        select
            @next_cell = cell
        from #map
        where
            col = @robot_col
            and row = @robot_row + 1;

        if @next_cell <> '#'
        begin
            if @next_cell in ('[', ']')
            begin
                truncate table #boxes;
                with boxes as
                (
                    select
                        convert(char(1), '[') as obj,
                        @robot_row + 1 as row,
                        case @next_cell when '[' then @robot_col else @robot_col - 1 end as col

                    union all

                    select
                        convert(char(1), case m.cell when ']' then '[' else m.cell end),
                        convert(int, m.row),
                        convert(int, case m.cell when ']' then m.col - 1 else m.col end)
                    from boxes as b
                    inner join #map as m on
                        m.row = b.row + 1
                        and m.col between b.col and b.col + 1
                        and m.cell <> '.'
                    where
                        b.obj <> '#'
                        and not (m.col = b.col + 1 and m.cell = ']')
                )
                insert into #boxes
                select distinct
                    obj,row,col
                from boxes;

                if not exists (select * from #boxes where obj = '#')
                begin
                    update m
                    set
                        m.cell = ch0.new
                    from #map as m
                    inner join
                    (
                        select
                            ch.col,
                            ch.row,
                            max(ch.cell) as new
                        from #boxes as b
                        cross apply
                        (
                            values
                            (
                                b.col,
                                b.row,
                                '.'
                            ),
                            (
                                b.col+1,
                                b.row,
                                '.'
                            ),
                            (
                                b.col,
                                b.row+1,
                                '['
                            ),
                            (
                                b.col+1,
                                b.row+1,
                                ']'
                            )
                        ) as ch (col, row, cell)
                        group by
                            ch.col, ch.row
                    ) as ch0 on
                        ch0.col = m.col
                        and ch0.row = m.row;
                end;
            end;

            if @next_cell = '.' or not exists (select * from #boxes where obj = '#')
            begin
                update #map
                set cell = case row when @robot_row then '.' else '@' end
                where
                    col = @robot_col
                    and row between @robot_row and @robot_row + 1;

                set @robot_row = @robot_row + 1;
            end;
        end;
    end;
    else if @move = '<'
    begin
        select
            @nearest_space = case when nearest_space > nearest_wall then nearest_space else null end
        from
        (
            select
                max(case when m.cell = '.' then m.col else null end) as nearest_space,
                max(case when m.cell = '#' then m.col else null end) as nearest_wall
            from #map as m
            where
                row = @robot_row
                and col < @robot_col
            group by row
        ) as x;

        if @nearest_space is not null
        begin
            update #map
            set
                col = case when col = @nearest_space then @robot_col else col-1 end
            where
                row = @robot_row
                and col between @nearest_space and @robot_col;

            set @robot_col = @robot_col - 1;
        end;
    end;
    else
    begin
        select
            @nearest_space = case when nearest_space < nearest_wall then nearest_space else null end
        from
        (
            select
                min(case when m.cell = '.' then m.col else null end) as nearest_space,
                min(case when m.cell = '#' then m.col else null end) as nearest_wall
            from #map as m
            where
                row = @robot_row
                and col > @robot_col
            group by row
        ) as x;

        if @nearest_space is not null
        begin
            update #map
            set
                col = case when col = @nearest_space then @robot_col else col+1 end
            where
                row = @robot_row
                and col between @robot_col and @nearest_space;

            set @robot_col = @robot_col + 1;
        end;
    end;

    set @move_num += 1;
end;

select
    sum(100 * (row - 1) + col - 1)
from #map
where
    cell = '[';
