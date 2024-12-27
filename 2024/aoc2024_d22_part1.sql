/*
A single SQL statement!!!

Not a very fast solution, but it ran on the order of seconds and I was really happy to not have to
spend hours on this one.
*/

declare @n nvarchar(max) = N'1
10
100
2024';

with c as
(
    select
        convert(bigint, s.value) as s,
        convert(int, 0) as i
    from string_split(replace(@n, char(10), ''), char(13)) as s

    union all

    select
        (d2.s ^ (d2.s * 2048)) % 16777216,
        i + 1
    from c
    cross apply
    (
        values ((c.s ^ (c.s * 64)) % 16777216)
    ) as d1 (s)
    cross apply
    (
        values ((d1.s ^ (d1.s / 32)) % 16777216)
    ) as d2 (s)
    where
        i < 2000
)
select
    sum(s)
from c
where
    i = 2000
option (maxrecursion 0);

