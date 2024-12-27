/*
This was one of those puzzles that seemed a bit too easy.

Part 1... recursive CTE. Feels kind of suggish, but okay. Let's see how Part 2 goes.
*/

declare @n nvarchar(max) = N'125 17';

declare @max_blink int = 25;

with
b as
(
    select
        convert(bigint, s.value) as v,
        0 as blink_count
    from string_split(@n, ' ') as s

    union all

    select
        x.v,
        blink_count + 1
    from b
    cross apply
    (
        select
            case
                when v = 0 then 1
                when len(convert(varchar, v)) % 2 = 0 then convert(bigint, left(convert(varchar, v), len(convert(varchar, v)) / 2))
                else v * 2024
            end

        union all
        
        select
            convert(bigint, right(convert(varchar, v), len(convert(varchar, v)) / 2))
        where
            len(convert(varchar, v)) % 2 = 0
    ) as x (v)
    where
        blink_count < @max_blink
)
select count_big(*)
from b
where
    blink_count = @max_blink
;
