/*
Can't get any simpler than these. Basically just smash stuff together, don't even worry about indexing. Happy December 1.
*/

declare @l varchar(max) = N'3   4
4   3
2   5
1   3
3   9
3   3';

--#1
with
q(c) as 
(
    select 
        value
    from string_split(replace(@l, char(10), ''), char(13)) as s
)
select
    sum(abs(ls.l - rs.r))
from
(
    select
        l,
        row_number() over (order by l) as lnum
    from
    (
        select
            convert(int, left(c, charindex(' ', c))) as l
        from q
    ) as q0
) as ls
inner join
(
    select
        r,
        row_number() over (order by r) as rnum
    from
    (
        select
            convert(int, right(c, len(c) - charindex(' ', c))) as r
        from q
    ) as q0
) as rs on
    rs.rnum = ls.lnum;


--#2
with
q(c) as 
(
    select 
        value
    from string_split(replace(@l, char(10), ''), char(13)) as s
)
select
    sum(ls.l * rs.cnt)
from
(
    select
        l
    from
    (
        select
            convert(int, left(c, charindex(' ', c))) as l
        from q
    ) as q0
) as ls
inner join
(
    select
        r,
        count(*) as cnt
    from
    (
        select
            convert(int, right(c, len(c) - charindex(' ', c))) as r
        from q
    ) as q0
    group by
        r
) as rs on
    ls.l = rs.r;
