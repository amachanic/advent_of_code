/*
Quite a bit more difficult than Part 1, but it used the same basic logic.

In Part 1 I found all pairs, then added an additional element to each pair that was related
to both of the members already in the pairs. In this part, I did the same but added an additional
element on every iteration inside of a loop (no more single SQL statement, yet again). The tricky
part was carrying along the members, and here I used a comma-separated string. It would have been
really nice to have an array here...
*/

declare @n nvarchar(max) = N'kh-tc
qp-kh
de-cg
ka-co
yn-aq
qp-ub
cg-tb
vc-aq
tb-ka
wh-tc
yn-cg
kh-ub
ta-co
de-co
tc-td
tb-wq
wh-td
ta-ka
td-qp
aq-cg
wq-ub
ub-vc
de-ta
wq-aq
wq-vc
wh-yn
ka-de
kh-ta
co-tc
wh-qp
tb-vc
td-yn';

if object_id('tempdb..#cmp') is not null
    drop table #cmp;

with n as
(
    select
        convert(char(2), left(value, 2)) as c1,
        convert(char(2), right(value, 2)) as c2
    from string_split(replace(@n, char(10), ''), char(13)) as s
)
select
    *
into #cmp
from n
where c1 < c2
union all
select
    c2,c1
from n
where
    c2 < c1
;

create unique clustered index c1c2 on #cmp (c1, c2);

declare @s int = 2;

if object_id('tempdb..#sets') is not null
    drop table #sets;

select
    c2,
    convert(varchar(max), concat(c1,',',c2)) as path,
    convert(int, 2) as size
into #sets
from #cmp;

create clustered index s on #sets (size);

while 1=1
begin
    insert into #sets
    select
        cz.c2,
        convert(varchar(max), concat(c.path,',',cz.c2)) as path,
        c.size + 1
    from #sets as c
    cross apply
    (
        select
            cx.c2
        from #cmp as cx
        where
            cx.c1 = c.c2
            and c.size-1 =
                (
                    select
                        count(*)
                    from
                    (
                        select
                            convert(char(2), s.value) as v,
                            row_number() over (order by 1/0) as r
                        from string_split(c.path, ',') as s
                    ) as x
                    inner join #cmp as cy on
                        cy.c1 = x.v
                        and cy.c2 = cx.c2
                    where
                        r < c.size
                )
    ) as cz
    where
        c.size = @s;

    if @@rowcount = 0
        break;

    set @s += 1;
end;

select top(1)
    path, size
from #sets
order by
    size desc;
