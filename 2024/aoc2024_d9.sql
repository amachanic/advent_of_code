/*
Part 1 was fairly simple, involving counting free space, counting allocated space, and then matching things up.

Part 2 was significantly trickier. For this one repeated iteration was necessary, checking a list of available
space against the remaining allocated space. I used a big while loop and a few temp tables to make this happen
and the entire time felt like doing AoC in SQL wasn't my best move.
*/

declare @n nvarchar(max) = N'2333133121414131402';

if object_id('tempdb..#nums') is not null
    drop table #nums;

with
a (n) as (select 1 union all select 1),
b (n) as (select x.n from a x, a y),
c (n) as (select x.n from b x, b y),
d (n) as (select x.n from c x, c y),
e (n) as (select x.n from d x, d y)
select
    row_number() over (order by 1/0) - 1 as n
into #nums
from e;

if object_id('tempdb..#pos') is not null
    drop table #pos;

declare @len int = (len(@n) / 2) + 1;

with
positions as
(
    select
        n as filenum,
        convert(int, substring(@n, (n*2)+1, 1)) as alloc,
        convert(int, isnull(nullif(substring(@n, (n*2)+2, 1), ''), 0)) as free
    from #nums
    where
        n < @len
)
select
    x.filenum,
    row_number() over (order by x.blocknum, x.filenum desc, x.pos_in_block) - 1 as diskpos
into #pos
from
(
    select
        filenum as blocknum,
        filenum,
        np.n as pos_in_block
    from positions as p
    inner join #nums as np on
        np.n < alloc
    union all
    select
        filenum as blocknum,
        null as filenum,
        np.n as pos_in_block
    from positions as p
    inner join #nums as np on
        np.n < free
) as x;


-- #1
select
    sum(free.diskpos * isnull(free.filenum, alloc.filenum))
from
(
    select
        *,
        sum(case when filenum is null then 1 else 0 end) over (order by diskpos) as freecount
    from #pos
    where
        diskpos <
        (
            select count(*)
            from #pos
            where
                filenum is not null
        )
) as free
left outer join
(
    select
        *,
        sum(case when filenum is not null then 1 else 0 end) over (order by diskpos desc) as alloccount
    from #pos
    where
        filenum is not null
) as alloc on
    alloc.alloccount = free.freecount
    and free.filenum is null
;


-- #2
if object_id('tempdb..#free') is not null
    drop table #free;

select
    freenum,
    count(*) as num_cells,
    min(diskpos) as first_pos
into #free
from
(
    select
        p2.*,
        case when filenum is not null then null else sum(case when filenum is null then freestart else 0 end) over (order by diskpos) end as freenum
    from
    (
        select
            *,
            case when filenum is null and lag(filenum, 1, -1) over (order by diskpos) is not null then 1 else 0 end as freestart
        from #pos
    ) as p2
) as p3
where
    freenum is not null
group by
    freenum
;

create index x on #free (first_pos, num_cells) where num_cells > 0;
create clustered index p on #pos (filenum);

declare @i int = (select max(filenum) from #pos);
declare @file_len int;
declare @newpos int;
declare @first_pos int;

if object_id('tempdb..#moved') is not null
    drop table #moved;

create table #moved
(
    filenum int,
    pos int,
    file_len int
);

while @i >= 0
begin
    select
        @file_len = count(*),
        @first_pos = min(diskpos)
    from #pos as p
    where
        p.filenum = @i;

    set @newpos = 
        (
            select top(1) 
                first_pos
            from #free
            where
                num_cells > 0
                and num_cells >= @file_len
                and first_pos < @first_pos
            order by first_pos
        );

    if @newpos is not null
    begin
        insert into #moved values (@i, @newpos, @file_len);

        update #free
        set
            first_pos += @file_len,
            num_cells -= @file_len
        where
            num_cells > 0
            and first_pos = @newpos;
    end;

    set @i = @i - 1;
end;

select
    sum(filenum * diskpos)
from
(
    select
        p.filenum,
        p.diskpos
    from #pos as p
    where
        p.filenum not in
        (
            select m.filenum from #moved as m
        )

    union all

    select
        m.filenum,
        x.pos
    from #moved as m
    cross apply
    (
        select
            n.n + m.pos as pos
        from #nums as n
        where
            n.n < m.file_len
    ) as x
) as y
;

