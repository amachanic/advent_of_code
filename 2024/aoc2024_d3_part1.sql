/*
Still pretty simple, but I had to generate some numbers for this. (Was solving in SQL Server 2017, so no generate_series function, sigh.)
*/

declare @n nvarchar(max) = N'xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))';

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
    )
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
    and mulend-secondnum between 1 and 3;
