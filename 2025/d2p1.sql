declare @r nvarchar(max) = N'11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124'

declare @t table (l_half varchar(25), s bigint, e bigint);
insert into @t (l_half, s, e)
select
    left(l_full.l, len(l_full.l)/2),
    convert(bigint, parts.l) as s,
    convert(bigint, parts.r) as e
from string_split(@r, ',') as s
cross apply (values (left(s.value, charindex('-', s.value) - 1), right(s.value, len(s.value) - charindex('-', s.value)))) as parts (l, r)
cross apply (values (case when len(parts.l) % 2 <> 0 then '1' + replicate('0', len(parts.l)) else parts.l end)) as l_full (l)
where
    not (len(parts.l) = len(parts.r) and len(parts.l) % 2 <> 0);

with nums
as
(
    select        
        convert(bigint, l_half + l_half) as l_full,
        l_half,
        s,
        e
    from @t
    where
        convert(bigint, l_half + l_half) <= e

    union all

    select        
        convert(bigint, h_next.h + h_next.h) as l_full,
        h_next.h,
        s,
        e
    from nums
    cross apply (values (convert(varchar(25), convert(bigint, l_half) + 1))) as h_next (h)
    where
        convert(bigint, h_next.h + h_next.h) <= e
)
select
    sum(l_full)
from nums
where
    l_full >= s
option (maxrecursion 0);
