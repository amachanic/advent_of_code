/*
Day 3, part 2... just a small modification.
*/

declare @n nvarchar(max) = N'xmul(2,4)&mul[3,7]!^don''t()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))';

with
a (n) as (select 1 union all select 1),
b (n) as (select x.n from a x, a y),
c (n) as (select x.n from b x, b y),
d (n) as (select x.n from c x, c y),
e (n) as (select x.n from d x, d y),
nums (n) as (select row_number() over (order by 1/0) from e)
select
    sum
    (
        convert(int,substring(@n, firstnum, comma-firstnum)) *
        convert(int,substring(@n, secondnum, mulend-secondnum))
    ) as num2
from
(
    select
        x0.s,
        lead(x0.s, 1, len(@n) + 1) over (order by x0.s) as e,
        x0.y_or_n
    from
    (
        select
            0 as s,
            'do()' as y_or_n
        union all
        select
            n,
            substring(@n, n, 4)
        from nums
        where
            substring(@n, n, 4) = 'do()'
        union all
        select
            n,
            substring(@n, n, 7)
        from nums
        where
            substring(@n, n, 7) = 'don''t()'
    ) as x0
) as valid
inner join
(
    select
        pos.*,
        substring(@n, mulstart, mulend+1-mulstart) as sub
    from nums
    cross apply
    (
        select
            n as mulstart,
            n+4 as firstnum,
            charindex(',', @n, n) as comma,
            charindex(',', @n, n)+1 as secondnum,
            charindex(')', @n, charindex(',', @n, n)) as mulend
    ) as pos
    where 
        substring(@n, n, 4) = 'mul('
        and comma-firstnum between 1 and 3
        and mulend-secondnum between 1 and 3
) as m on
    m.mulstart between valid.s and valid.e
where
    valid.y_or_n = 'do()';
