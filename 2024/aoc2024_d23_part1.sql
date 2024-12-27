/*
I really loved this challenge - I thought it was one of the most SQL-friendly in the entire month
to date, and I was really happy with my solution which is just a simple three-part join. I did a
little bit of preprocessing first to alphabetize the inputs, so as to make things simpler.
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

create unique index c1c2 on #cmp (c1, c2);

select
    count(*)
from
(
    select
        cx.c1,cx.c2,cy.c2 as c3
    from #cmp as cx
    inner join #cmp as cy on cy.c1 = cx.c1
    inner join #cmp as cz on cz.c1 = cx.c2
    where
        cy.c2 = cz.c2
) as x
where
    x.c1 like 't%'
    or x.c2 like 't%'
    or x.c3 like 't%';

