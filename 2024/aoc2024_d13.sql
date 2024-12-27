/*
Part 1: "Oh, no problem, a little brute force and we're good to go."

Part 2: [Wait a long time] ... "Arithmetic overflow..."

This turned into a linear algebra problem. Fun!
*/

declare @n nvarchar(max) = N'Button A: X+94, Y+34
Button B: X+22, Y+67
Prize: X=8400, Y=5400

Button A: X+26, Y+66
Button B: X+67, Y+21
Prize: X=12748, Y=12176

Button A: X+17, Y+86
Button B: X+84, Y+37
Prize: X=7870, Y=6450

Button A: X+69, Y+23
Button B: X+27, Y+71
Prize: X=18641, Y=10279';

if object_id('tempdb..#grps') is not null
    drop table #grps;

select
    grp,
    min(case when xy = 'X' and tag = 'Button A' then xy_val else null end) as button_a_x,
    min(case when xy = 'Y' and tag = 'Button A' then xy_val else null end) as button_a_y,
    min(case when xy = 'X' and tag = 'Button B' then xy_val else null end) as button_b_x,
    min(case when xy = 'Y' and tag = 'Button B' then xy_val else null end) as button_b_y,
    min(case when xy = 'X' and tag = 'Prize' then xy_val else null end) as prize_x,
    min(case when xy = 'Y' and tag = 'Prize' then xy_val else null end) as prize_y
into #grps
from
(
    select
        s0.*,
        left(trim(xy.value), 1) as xy,
        convert(int, substring(trim(xy.value), 3, len(xy.value))) as xy_val
    from
    (
        select
            left(s.value, charindex(':', s.value) - 1) as tag,
            substring(s.value, charindex(':', s.value) + 2, len(s.value)) as info,
            (row_number() over (order by 1/0) - 1) / 3 as grp
        from string_split(replace(@n, char(10), ''), char(13)) as s
        where
            s.value <> ''
    ) as s0
    cross apply string_split(s0.info, ',') as xy
) as s1
group by
    s1.grp;

if object_id('tempdb..#nums') is not null
    drop table #nums;

with
a (n) as (select 1 union all select 1),
b (n) as (select x.n from a x, a y),
c (n) as (select x.n from b x, b y),
d (n) as (select x.n from c x, c y)
select top(100)
    row_number() over (order by 1/0) - 1 as n
into #nums
from d;


-- #1
select
    sum(num)
from #grps as g
cross apply
(
    select top(1)
        a * 3 + b as num
    from
    (
        select
            a.n as a,
            b.n as b,
            g.button_a_x * a.n + g.button_b_x * b.n as x_val,
            g.button_a_y * a.n + g.button_b_y * b.n as y_val
        from #nums a, #nums b
    ) as x0
    where
        x0.x_val = g.prize_x
        and x0.y_val = g.prize_y
    order by num
) as x;


-- #2 
/*
First, convert things into a linear series: (a*x + b*y = c)

a*button_a_x + b*button_b_x = prize_x
a*button_a_y + b*button_b_y = prize_y

Now put a and b on their own sides for each part:

a = (prize_x - b*button_b_x)/button_a_x
b = (prize_y - a*button_a_y)/button_b_y

Now convert into simpler variable names so I don't have to type as much.
And also convert the division into multiplication so it's easier to move around.

a = (px - b*bx)*(1/ax)
b = (py - a*ay)*(1/by)

And now, solve for b!
b = py*(1/by) - px*(1/ax)*ay*(1/by) + b*bx*(1/ax)*ay*(1/by)
b = (-py*(1/by) + px*(1/ax)*ay*(1/by)) / (bx*(1/ax)*ay*(1/by) - 1)

That can probably be simplified, but it was fine. I had some issues with floating
point error due to the very large numbers that were produced as part of the problem,
but it worked just well enough to give me a passable answer. Had this gotten any
bigger I would have had to solve out some of the division above to make this generate
more accurate integers.
*/


select
    sum(round(a, 0) * 3 + round(b, 0))
from 
(
    select
        convert(float, button_a_x) as ax,
        convert(float, button_a_y) as ay,
        convert(float, button_b_x) as bx,
        convert(float, button_b_y) as [by],
        convert(float, prize_x+10000000000000) as px,
        convert(float, prize_y+10000000000000) as py
    from #grps as g0
) as g
cross apply
(    
    select
        (-py*(1/[by]) + px*(1/ax)*ay*(1/[by])) / (bx*(1/ax)*ay*(1/[by]) - 1) as b
) as x
cross apply
(
    select
      (px - b*bx)*(1/ax) as a
) as y
where
    --absolutely shoddy way to confirm an integer...
    convert(numeric(26,2), b) = convert(numeric(26,0), b)
    and convert(numeric(26,2), a) = convert(numeric(26,0), a) 
;
