/*
Fairly simple inter-row analysis on this one. Still a single SQL statement per part!
*/

declare @n nvarchar(max) = N'7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9';

-- #1 
with 
dat_flat as
(
    select 
        value as row_val,
        row_number() over (order by 1/0) as row_num
    from string_split(replace(@n, char(10), ''), char(13)) as s
),
dat_rows as
(
    select
        dat_flat.row_num,
        v.*
    from dat_flat
    cross apply
    (
        select convert(int, s.value) as value, row_number() over (order by 1/0) as val_num
        from string_split(dat_flat.row_val, ' ') as s
    ) as v
)
select
    count(*)
from
(
    select
        row_num
    from
    (
        select
            row_num,
            case 
                when next_value < value then 'd'
                when next_value > value then 'i'
                else 'u'
            end as direction,
            abs(next_value-value) as diff
        from
        (
            select
                *,
                lead(value) over (partition by row_num order by val_num) as next_value
            from dat_rows
        ) as l
        where
            next_value is not null
    ) as x
    group by 
        row_num
    having
        min(direction) = max(direction)
        and count(*) = sum(case when diff between 1 and 3 then 1 else 0 end)
) as y;


-- #2
with 
dat_flat as
(
    select
        value as row_val,
        row_number() over (order by 1/0) as row_num
    from string_split(replace(@n, char(10), ''), char(13)) as s
),
dat_rows as
(
    select
        dat_flat.row_num,
        v.*
    from dat_flat
    cross apply
    (
        select convert(int, s.value) as value, row_number() over (order by 1/0) as val_num
        from string_split(dat_flat.row_val, ' ') as s
    ) as v
),
all_combos as
(
    select
        d.row_num,
        0 as missing_val,
        d.value,
        d.val_num
    from dat_rows as d
    union all
    select
        d0.row_num,
        d1.val_num as missing_val,
        d0.value,
        row_number() over (partition by d0.row_num, d1.val_num order by d0.val_num) as val_num
    from dat_rows as d0
    inner join dat_rows as d1 on
        d1.row_num = d0.row_num
        and d0.val_num <> d1.val_num
)
select
    count(*)
from
(
    select distinct
        row_num
    from
    (
        select
            row_num,
            missing_val,
            value,
            next_value,
            case 
                when next_value < value then 'd'
                when next_value > value then 'i'
                else 'u'
            end as direction,
            abs(next_value-value) as diff
        from
        (
            select
                *,
                lead(value) over (partition by row_num, missing_val order by val_num) as next_value
            from all_combos
        ) as l
        where
            next_value is not null
    ) as x
    group by 
        row_num, missing_val
    having
        min(direction) = max(direction)
        and count(*) = sum(case when diff between 1 and 3 then 1 else 0 end)
) as y;
