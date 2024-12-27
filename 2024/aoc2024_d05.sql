/*
Couple of temp tables and some basic SQL logic saves the day :-)
*/

declare @n nvarchar(max) = N'47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47';

declare @separator int = (select r from (select value, row_number() over (order by 1/0) as r from string_split(replace(@n, char(10), ''), char(13)) as s) as s0 where value = '');

if object_id('tempdb..#rules') is not null
    drop table #rules;

select
    convert(int, left(value, 2)) as p1,
    convert(int, right(value, 2)) as p2
into #rules
from (select value, row_number() over (order by 1/0) as r from string_split(replace(@n, char(10), ''), char(13)) as s) as r
where
    r.r < @separator;

if object_id('tempdb..#upd') is not null
    drop table #upd;

select
    u.upd_num,
    convert(int, u_ord.value) as upd_page,
    row_number() over (partition by u.upd_num order by 1/0) as upd_order
into #upd
from
(
    select
        *,
        row_number() over (order by 1/0) as upd_num
    from (select value, row_number() over (order by 1/0) as r from string_split(replace(@n, char(10), ''), char(13)) as s) as u0
    where
        u0.r > @separator
) as u
cross apply string_split(u.value, ',') as u_ord;

-- #1
with
incorrect_updates as
(
    select distinct
        u.upd_num
    from #upd as u
    where
        exists
        (
            select
                *
            from #upd as u1
            where
                u1.upd_num = u.upd_num
                and u1.upd_order > u.upd_order
                and exists
                (
                    select
                        *
                    from #rules as r1
                    where
                        r1.p1 = u1.upd_page
                        and r1.p2 = u.upd_page
                )
        )
),
correct_updates as
(
    select distinct
        uc.upd_num
    from #upd as uc
    where
        uc.upd_num not in (select upd_num from incorrect_updates)
)
select
    sum(upd_page)
from
(
    select
        u2.upd_num,
        u2.upd_page,
        u2.upd_order,
        ((max(u2.upd_order) over (partition by u2.upd_num)) / 2) + 1 as desired_order
    from correct_updates as i
    inner join #upd as u2 on
        u2.upd_num = i.upd_num
) as u3
where
    u3.desired_order = u3.upd_order
;



-- #2
with
incorrect_updates as
(
    select distinct
        u.upd_num
    from #upd as u
    where
        exists
        (
            select
                *
            from #upd as u1
            where
                u1.upd_num = u.upd_num
                and u1.upd_order > u.upd_order
                and exists
                (
                    select
                        *
                    from #rules as r1
                    where
                        r1.p1 = u1.upd_page
                        and r1.p2 = u.upd_page
                )
        )
)
select
    sum(x1.upd_page)
from
(
    select
        x.upd_num,
        x.upd_page,
        row_number() over (partition by x.upd_num order by x.c desc) as upd_order,
        ((max(x.upd_order) over (partition by x.upd_num)) / 2) + 1 as desired_order
    from
    (
        select 
            *,
            (
                select
                    count(*)
                from #upd as u1
                inner join #rules as r1 on
                    r1.p1 = u.upd_page
                    and r1.p2 = u1.upd_page
                where
                    u1.upd_num = u.upd_num
                    and u1.upd_page <> u.upd_page
            ) as c
        from #upd as u
        where
            u.upd_num in (select i.upd_num from incorrect_updates as i)
    ) as x
) as x1
where
    x1.upd_order = x1.desired_order
;