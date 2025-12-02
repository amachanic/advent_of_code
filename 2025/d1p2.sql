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
    convert(int, replace(replace(replace(value, char(13), ''), 'R', ''), 'L', '-'))
from string_split(@r, char(10));

with vals as
(
    select
        0 as pos,
        50 as curr,
        0 as n,
        0 as passed_zero

    union all

    select
        t.pos,
        final.n,
        t.num,
        abs(t.num) / 100 + 
            case
                when
                    (
                        v0.curr <> 0 and
                        (
                            ((t.num % 100) < 0 and final.n > v0.curr)
                            or ((t.num % 100) > 0 and final.n < v0.curr)
                        )
                    )
                    or final.n = 0
                        then 1
                else 0
            end
    from vals as v0
    inner join @t as t on
        t.pos = v0.pos + 1
    cross apply
    (
        values (v0.curr + t.num % 100)
    ) as nxt(n)
    cross apply
    (
        values
        (
            case
                when nxt.n < 0 then 100 + nxt.n
                when nxt.n > 99 then nxt.n - 100
                else nxt.n
            end
        )
    ) as final(n)
)
select
    sum(passed_zero)
from vals
option (maxrecursion 0);
