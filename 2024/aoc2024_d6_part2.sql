/*
The first part was not too difficult; this part was relatively insane. I used the output from the
first part as input to the second section - so the first part is basically repeated below. After
that I found all of the positions visited, and ran the simulation for each position separately in
a big loop, checking for cycles.

For this second part, I spent a lot of time getting it to return fast enough, and it's still not at
all well enough optimized after all of that. Among other things I converted the recursive CTE logic
to a while loop. I experimented with a couple of different loop-detection techniques and found that
creating a large enumerated path in a VARCHAR(MAX) variable is extremely expensive. Using a table
turned out to be better there.

Further optimization is possible, for sure. For example, there's no need to do each move along a straight
path: The code can instead look ahead to the next obstacle. In addiiton, there's no need to run each
simulation from the initial starting point. It can instead start just before the guard encounters the
obstacle we're testing for. I'm sure there are other optimizations.
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
......#...';

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

if object_id('tempdb..#pos') is not null
    drop table #pos;

with
visits as
(
    select
        @startr as r,
        @startc as c,
        convert(varchar(5), 'up') as dir,
        convert(int, 0) as move

    union all

    select
        x.r,
        x.c,
        x.dir,
        x.move + 1
    from
    (
        select
            case nextchar.p when '#' then v.r else nextpos.r end as r,
            case nextchar.p when '#' then v.c else nextpos.c end as c,
            case nextchar.p
                when '#' then convert(varchar(5), case v.dir when 'up' then 'right' when 'right' then 'down' when 'down' then 'left' when 'left' then 'up' end)
                else v.dir
            end as dir,
            v.move
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
    ) as x
)
select distinct
    r, c
into #pos
from visits
where
    not (r = @startr and c = @startc)
option(maxrecursion 0);

declare @rowlen int = (select len(cols) from #n where r = 1);

if object_id('tempdb..#stuff') is not null
    drop table #stuff;

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
    #n.r,
    nums.n as c,
    substring(cols, nums.n, 1) as v
into #stuff
from #n, nums;

create unique clustered index rc on #stuff (r, c);

if object_id('tempdb..#lvl') is not null
    drop table #lvl;

select distinct
    @startr as r,
    @startc as c,
    convert(varchar(10), 'up') as dir,
    #pos.r as extra_r,
    #pos.c as extra_c,
    convert(int, 0) as lvl
into #lvl
from #pos;

create clustered index l on #lvl (lvl);
create unique index m on #lvl (extra_r, extra_c, r, c, dir);

declare @l int = 0;

while 1=1
begin
    insert into #lvl
    select
        case when isnull(i.is_collision, 0) = 1 then 0 else x.r end as r,
        case when isnull(i.is_collision, 0) = 1 then 0 else x.c end as c,
        x.dir,
        x.extra_r,
        x.extra_c,
        @l + 1
    from
    (
        select
            case obs.p when '#' then v.r else nextpos.r end as r,
            case obs.p when '#' then v.c else nextpos.c end as c,
            case obs.p
                when '#' then convert(varchar(5), case v.dir when 'up' then 'right' when 'right' then 'down' when 'down' then 'left' when 'left' then 'up' end)
                else v.dir
            end as dir,
            v.extra_r,
            v.extra_c
        from #lvl as v
        cross apply
        (
            values
                (
                    v.r + case dir when 'up' then -1 when 'down' then 1 else 0 end,
                    v.c + case dir when 'right' then 1 when 'left' then -1 else 0 end
                )
        ) as nextpos(r, c)
        inner join #stuff as n on
            n.r = nextpos.r
            and n.c = nextpos.c
        cross apply
        (
            values
            (
                case when n.r = v.extra_r and n.c = v.extra_c then '#' else n.v end
            )
        ) as obs (p)
        where
            v.lvl = @l
    ) as x
    outer apply
    (
        select
            1
        from #lvl as l0
        where
            l0.extra_r = x.extra_r
            and l0.extra_c = x.extra_c
            and l0.r = x.r
            and l0.c = x.c
            and l0.dir = x.dir
    ) as i (is_collision);

    if @@rowcount = 0
        break;

    set @l = @l + 1;
end;

select
    count(*)
from #lvl
where
    r = 0;

