/*
This one was basically just lots of prep work on the input. The actual puzzle was very simple.
*/

declare @n nvarchar(max) = N'#####
.####
.####
.####
.#.#.
.#...
.....

#####
##.##
.#.##
...##
...#.
...#.
.....

.....
#....
#....
#...#
#.#.#
#.###
#####

.....
.....
#.#..
###..
###.#
###.#
#####

.....
.....
.....
#....
#.#..
#.#.#
#####';

if object_id('tempdb..#stuff') is not null
    drop table #stuff;

select
    lock_or_key,    
    isnull(case lock_or_key when 'lock' then max1-1 else 7-min1 end, 0) as p1,
    isnull(case lock_or_key when 'lock' then max2-1 else 7-min2 end, 0) as p2,
    isnull(case lock_or_key when 'lock' then max3-1 else 7-min3 end, 0) as p3,
    isnull(case lock_or_key when 'lock' then max4-1 else 7-min4 end, 0) as p4,
    isnull(case lock_or_key when 'lock' then max5-1 else 7-min5 end, 0) as p5
into #stuff
from
(
    select
        grp,
        case when min(case when grp_r = 1 then value else null end) = '#####' then 'lock' else 'key' end as lock_or_key,
        min(case when substring(value, 1, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as min1,
        min(case when substring(value, 2, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as min2,
        min(case when substring(value, 3, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as min3,
        min(case when substring(value, 4, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as min4,
        min(case when substring(value, 5, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as min5,
        min(case when substring(value, 6, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as min6,
        max(case when substring(value, 1, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as max1,
        max(case when substring(value, 2, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as max2,
        max(case when substring(value, 3, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as max3,
        max(case when substring(value, 4, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as max4,
        max(case when substring(value, 5, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as max5,
        max(case when substring(value, 6, 1) = '#' and grp_r not in (1, 7) then grp_r else null end) as max6
    from
    (
        select
            grp,
            row_number() over (partition by grp order by r) as grp_r,
            value
        from
        (
            select
                value,
                row_number() over (order by 1/0) as r,
                (row_number() over (order by 1/0)) / 8 as grp
            from string_split(replace(@n, char(10), ''), char(13)) as s
        ) as x
        where
            x.value <> ''
    ) as y
    group by
        grp
) as z;

select
    count(*)
from #stuff as l
cross join #stuff as k
where
    l.lock_or_key = 'lock'
    and k.lock_or_key = 'key'
    and l.p1 + k.p1 <= 5
    and l.p2 + k.p2 <= 5
    and l.p3 + k.p3 <= 5
    and l.p4 + k.p4 <= 5
    and l.p5 + k.p5 <= 5
;
