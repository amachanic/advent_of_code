/*
Both parts were pretty simple to solve, requiring nothing more than iteration and a few checks.
(Brute force for the win!) I decided to use a recursive CTE to walk through the logic, which
made it really easy, but when I ran the full input I was shocked by how slowly it ran.

After spending some time digging in, I discovered the issue: There is a sort in each of the two parts'
query plans that runs out of memory due to a massive underestimation. I fixed the issue (sort of) with
a quick and dirty trick... but re-writing as a while loop would be much nicer. This runs far more slowly
than it should, even though it's a brute force solution.
*/

declare @n nvarchar(max) = N'190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20';

if object_id('tempdb..#x') is not null
    drop table #x;

with
base as 
(
    select
        convert(bigint, left(s1.value, charindex(':', s1.value) - 1)) as result,
        substring(s1.value, charindex(':', s1.value) + 2, len(s1.value)) as inputs,
        row_number() over (order by 1/0) as resnum
    from string_split(replace(@n, char(10), ''), char(13)) as s1
)
select
    base.resnum,
    base.result,
    i.*
into #x
from base
cross apply
(
    select
        convert(bigint, s2.value) as num,
        row_number() over (order by 1/0) as pos
    from string_split(base.inputs, ' ') as s2
) as i;

declare @zero int = 0;


-- #1
with
c as
(
    select
        resnum,
        result,
        num,
        pos
    from #x
    where
        pos = 1

    union all

    select
        #x.resnum,
        #x.result,
        c.num + #x.num as num,
        #x.pos
    from c
    inner join #x on
        #x.pos = c.pos + 1
        and #x.resnum = c.resnum

    union all

    select
        #x.resnum,
        #x.result,
        c.num * #x.num as num,
        #x.pos
    from c
    inner join #x on
        #x.pos = c.pos + 1
        and #x.resnum = c.resnum
)
select
    sum(result)
from
(
    select distinct
        resnum, result
    from
    (
        select
            c2.*,
            rank() over (partition by resnum order by pos desc) as r
        from
        (
            select
                resnum, result, num, pos
            from c

            union all

            select top(@zero)
                null, null, null, null
            from sys.all_columns as x, sys.all_columns as y
        ) as c2
    ) as c1
    where
        c1.r = 1
        and result = num
) as c2
option (optimize for (@zero=1000000), concat union);


-- #2
with
c as
(
    select
        resnum,
        result,
        num,
        pos
    from #x
    where
        pos = 1

    union all

    select
        #x.resnum,
        #x.result,
        c.num + #x.num as num,
        #x.pos
    from c
    inner join #x on
        #x.pos = c.pos + 1
        and #x.resnum = c.resnum

    union all

    select
        #x.resnum,
        #x.result,
        c.num * #x.num as num,
        #x.pos
    from c
    inner join #x on
        #x.pos = c.pos + 1
        and #x.resnum = c.resnum

    union all

    select
        #x.resnum,
        #x.result,
        convert(bigint, convert(varchar(100), c.num) + convert(varchar(100), #x.num)) as num,
        #x.pos
    from c
    inner join #x on
        #x.pos = c.pos + 1
        and #x.resnum = c.resnum
)
select sum(result)
from
(
    select distinct
        resnum, result
    from
    (
        select
            c2.*,
            rank() over (partition by resnum order by pos desc) as r
        from
        (
            select
                resnum, result, num, pos
            from c

            union all

            select top(@zero)
                null, null, null, null
            from sys.all_columns as x, sys.all_columns as y, sys.all_columns as z
        ) as c2
    ) as c1
    where
        c1.r = 1
        and result = num
) as c2
option (optimize for (@zero=50000000), concat union);
