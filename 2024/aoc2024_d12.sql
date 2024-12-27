/*
This day's puzzles were different variations on a flood problem. I tried solving them with a
recursive CTE, but it simply couldn't move fast enough. I wound up heavily pre-processing the
input set using LAG and LEAD functions to find edges and edge sequences, and then used a while
loop to walk outward at each level to flood the spaces.

Unfortunately I didn't separately save my Part 1 work before starting on Part 2, so both bits
are together. It's mostly the same base code, except that I had to add a bit of additional 
LAG and LEAD logic for Part 2.
*/

declare @n nvarchar(max) = N'RRRRIICCFF
RRRRIICCCF
VVRRRCCFFF
VVRCCCJFFF
VVVVCJJCFE
VVIVCCJJEE
VVIIICJJEE
MIIIIIJJEE
MIIISIJEEE
MMMISSJEEE';

if object_id('tempdb..#rows') is not null
    drop table #rows;

select
    s.value as cols,
    row_number() over (order by 1/0) as row
into #rows
from string_split(replace(@n, char(13), ''), char(10)) as s;

if object_id('tempdb..#cells') is not null
    drop table #cells;

declare @rowlen int = (select len(cols) from #rows where row = 1);

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
),
vals as
(
    select
        #rows.row,
        nums.n as col,
        substring(#rows.cols, nums.n, 1) as v
    from #rows, nums
)
select
    v0.*,
    case 
        when top_edge = 1 and 
            (
                0 = lag(top_edge, 1, 0) over (partition by row order by col)
                or v != lag(v, 1, '') over (partition by row order by col)
            )
                then 1 
        else 0 
    end as top_edge_start,
    case
        when bottom_edge = 1 and 
            (
                0 = lag(bottom_edge, 1, 0) over (partition by row order by col)
                or v != lag(v, 1, '') over (partition by row order by col)
            )
                then 1
        else 0
    end as bottom_edge_start,
    case
        when left_edge = 1 and
            (
                0 = lag(left_edge, 1, 0) over (partition by col order by row)
                or v != lag(v, 1, '') over (partition by col order by row)
            )
                then 1
        else 0
    end as left_edge_start,
    case
        when right_edge = 1 and
            (
                0 = lag(right_edge, 1, 0) over (partition by col order by row)
                or v != lag(v, 1, '') over (partition by col order by row)
            )
                then 1
        else 0
    end as right_edge_start
into #cells
from
(
    select
        v.*,
        case when v = lag(v) over (partition by col order by row) then 0 else 1 end as top_edge,
        case when v = lead(v) over (partition by col order by row) then 0 else 1 end as bottom_edge,
        case when v = lag(v) over (partition by row order by col) then 0 else 1 end as left_edge,
        case when v = lead(v) over (partition by row order by col) then 0 else 1 end as right_edge
    from vals as v
) as v0
;

create clustered index rc on #cells (row, col);

if object_id('tempdb..#lvl') is not null
    drop table #lvl;

select
    row,
    col,
    row as f_row,
    col as f_col,
    top_edge,
    bottom_edge,
    left_edge,
    right_edge,
    convert(int, 1) as lvl
into #lvl
from #cells as c
where
    c.top_edge = 1
    and c.left_edge = 1;

create clustered index l on #lvl (lvl, f_row, f_col, row, col);
create index rc on #lvl (f_row, f_col, row, col);

declare @i int = 1;

while 1=1
begin
    insert into #lvl
    select distinct
        next.row,
        next.col,
        rc.f_row,
        rc.f_col,
        c0.top_edge,
        c0.bottom_edge,
        c0.left_edge,
        c0.right_edge,
        @i + 1
    from #lvl as rc
    cross apply
    (
        select
            rc.row-1, rc.col
        where
            rc.top_edge = 0

        union all

        select
            rc.row+1, rc.col
        where
            rc.bottom_edge = 0

        union all

        select
            rc.row, rc.col-1
        where
            rc.left_edge = 0

        union all

        select
            rc.row, rc.col+1
        where
            rc.right_edge = 0
    ) as next (row, col)
    inner join #cells as c0 on
        c0.row = next.row
        and c0.col = next.col
    where
        rc.lvl = @i
        and not exists (select * from #lvl as rc2 where rc2.f_col = rc.f_col and rc2.f_row = rc.f_row and rc2.col = next.col and rc2.row = next.row);

    if @@rowcount = 0
        break;

    set @i = @i + 1;
end;


-- #1
select
    sum(area * edge)
from
(
    select
        grp,
        count(*) as area,
        sum(edge_count) as edge
    from
    (
        select
            row,
            col,
            min(top_edge+bottom_edge+left_edge+right_edge) as edge_count,
            min(concat(f_row,'.',f_col)) as grp
        from #lvl as rc
        group by
            row,col
    ) as x
    group by grp
) as y;


-- #2
select
    sum(area*edges)
from
(
    select
        grp,
        count(*) as area,
        sum(edges) as edges
    from
    (
        select
            c.row,
            c.col,
            top_edge_start+bottom_edge_start+left_edge_start+right_edge_start as edges,
            l.grp
        from #cells as c
        inner join
        (
            select
                row,
                col,
                min(concat(f_row,'.',f_col)) as grp
            from #lvl as rc
            group by
                row,col
        ) as l on
            l.row = c.row
            and l.col = c.col
    ) as x
    group by grp
) as y;
