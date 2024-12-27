/*
This one wasn't too bad after Part 1 and a bit of thinking. As prefixes pair with other prefixes
to create larger patterns, the counts aggregate together. This is only a slight modification from
my Part 1 solution: I added a column to track counts and replaced DISTINCT with SUM/GROUP BY.
*/

declare @n nvarchar(max) = N'r, wr, b, g, bwu, rb, gb, br

brwrr
bggr
gbbr
rrbgbr
ubwu
bwurrg
brgr
bbrgwb';

if object_id('tempdb..#towels') is not null
    drop table #towels;

select
    convert(varchar(100), trim(s1.value)) collate Latin1_General_Bin2 as towel
into #towels
from
(
    select
        s.value,
        row_number() over (order by 1/0) as r
    from string_split(replace(@n, char(10), ''), char(13)) as s
) as x
cross apply string_split(x.value, ',') as s1
where
    x.r = 1;

create clustered index t on #towels (towel);

if object_id('tempdb..#patterns') is not null
    drop table #patterns;

select
    convert(varchar(100), p.value) collate Latin1_General_Bin2 as pattern
into #patterns
from
(
    select
        s.value,
        row_number() over (order by 1/0) as r

    from string_split(replace(@n, char(10), ''), char(13)) as s
) as p
where
    p.r > 2;

create index p on #patterns (pattern);

delete from #towels
where not exists (select * from #patterns where pattern like '%'+towel+'%');

if object_id('tempdb..#prefixes') is not null
    drop table #prefixes;

with
c as
(
    select
        convert(int, 1) as prefix_len,
        convert(varchar(100), substring(pattern, 1, 1)) as prefix,
        pattern
    from #patterns

    union all

    select
        prefix_len + 1,
        convert(varchar(100), substring(pattern, 1, prefix_len)),
        pattern
    from c
    where
        len(pattern) >= prefix_len

)
select distinct
    prefix
into #prefixes
from c;

create clustered index len_pre on #prefixes (prefix);

if object_id('tempdb..#moves') is not null
    drop table #moves;

select
    t.towel,
    convert(int, 1) as move,
    convert(bigint, 1) as cnt
into #moves
from #towels as t
where
    exists (select * from #prefixes as p where p.prefix = t.towel)

create clustered index m on #moves (move);
create index t on #moves (towel);

declare @move int = 1;

while 1=1
begin
    insert into #moves
    select
        convert(varchar(100), c.towel + t.towel),
        @move + 1,
        sum(c.cnt)
    from #moves as c
    inner join #towels as t on
        exists (select * from #prefixes as p where p.prefix = c.towel + t.towel)
    where
        c.move = @move
    group by
        convert(varchar(100), c.towel + t.towel)
    ;

    if @@rowcount = 0
        break;

    set @move += 1;
end;

select
    sum(convert(bigint, cnt)) as m
from #moves as m
where
    exists (select * from #patterns as p where p.pattern = m.towel)
;
