/*
This one was really involved. Nice twist on a walk, where the walk itself manipulates the board.

To make this work I basically just stored the state of the board after every move, and played it
forward. This was difficult enough for me without attempting to optimize.
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

--probably not needed, but just in case...
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

set nocount on;

while 1=1
begin
    declare @move char(1) = (select move from #moves where move_num = @move_num);
    if @move is null
        break;

    --find the next wall
    --find the nearest space in between that wall and the robot...
    if @move = '^'
    begin
        select
            @nearest_space = case when nearest_space > nearest_wall then nearest_space else null end
        from
        (
            select
                max(case when m.cell = '.' then m.row else null end) as nearest_space,
                max(case when m.cell = '#' then m.row else null end) as nearest_wall
            from #map as m
            where
                col = @robot_col
                and row < @robot_row
            group by col
        ) as x;

        if @nearest_space is not null
        begin
            update #map
            set
                row = case when row = @nearest_space then @robot_row else row-1 end
            where
                col = @robot_col
                and row between @nearest_space and @robot_row;

            set @robot_row = @robot_row - 1;
        end;
    end;
    else if @move = 'v'
    begin
        select
            @nearest_space = case when nearest_space < nearest_wall then nearest_space else null end
        from
        (
            select
                min(case when m.cell = '.' then m.row else null end) as nearest_space,
                min(case when m.cell = '#' then m.row else null end) as nearest_wall
            from #map as m
            where
                col = @robot_col
                and row > @robot_row
            group by col
        ) as x;

        if @nearest_space is not null
        begin
            update #map
            set
                row = case when row = @nearest_space then @robot_row else row+1 end
            where
                col = @robot_col
                and row between @robot_row and @nearest_space;

            set @robot_row = @robot_row + 1;
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
    cell = 'O';
