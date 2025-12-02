declare @r nvarchar(max) = N'11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124'

declare @t table (l_part varchar(25), s bigint, e bigint, num int);
insert into @t (l_part, s, e, num)
select
    left(case when len(parts.l) < len(parts.r) then '1' + replicate('0', len(parts.l) - 1) else parts.l end, ranges.value),
    convert(bigint, parts.l) as s,
    convert(bigint, parts.r) as e,
    x.plen / ranges.value
from string_split(@r, ',') as s
cross apply (values (left(s.value, charindex('-', s.value) - 1), right(s.value, len(s.value) - charindex('-', s.value)))) as parts (l, r)
cross apply generate_series(1, 5) as ranges
cross apply(select len(parts.r) union select len(parts.l)) as x (plen)
where
    ranges.value < x.plen
    and x.plen % ranges.value = 0;

with nums
as
(
    select
        convert(bigint, replicate(l_part, num)) as l_full,
        l_part,
        s,
        e,
        num
    from @t
    where
        convert(bigint, replicate(l_part, num)) <= e

    union all

    select        
        convert(bigint, replicate(h_next.h, num)) as l_full,
        h_next.h,
        s,
        e,
        num
    from nums
    cross apply (values (convert(varchar(25), convert(bigint, l_part) + 1))) as h_next (h)
    where
        len(h_next.h) = len(l_part)
        and convert(bigint, replicate(h_next.h, num)) <= e
)
select
    sum(l_full)
from
(
    select distinct
        l_full
    from nums
    where
        l_full >= s
) as x
option (maxrecursion 0);
