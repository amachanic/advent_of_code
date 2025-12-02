declare @r nvarchar(max) = N'L68
L30
R48
L5
R60
L55
L1
L99
R14
L82';

declare @t table (num int, pos int identity(1,1), primary key (pos));
insert into @t (num)
select
    convert(int, replace(replace(replace(value, char(13), ''), 'R', ''), 'L', '-')) % 100
from string_split(@r, char(10));

with vals as
(
    select
        0 as pos,
        50 as curr,
        0 as n

    union all

    select
        t.pos,
        case
            when nxt.n < 0 then 100 + nxt.n
            when nxt.n > 99 then nxt.n - 100
            else nxt.n
        end,
        t.num
    from vals as v0
    inner join @t as t on
        t.pos = v0.pos + 1
    cross apply
    (
        values (v0.curr + t.num)
    ) as nxt(n)
)
select
    sum(case when curr = 0 then 1 else 0 end)
from vals
option (maxrecursion 0);
