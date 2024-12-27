/*
This was a lot of work to set up and I felt a bit tired afterward. There were only five inputs,
so instead of writing a loop I just ran each input manually and added the results up at the end.
*/

declare @num_seq char(5) = 'A' + '029A';

if object_id('tempdb..#num_keypad') is not null
    drop table #num_keypad;

select
    convert(varchar, x.n) as num,
    abs(((n-1)/3)-3) as row,
    ((n-1)%3)+1 as col
into #num_keypad
from (values (1),(2),(3),(4),(5),(6),(7),(8),(9)) as x (n)
union all
select
    '0', 4, 2
union all
select
    'A', 4, 3
;

if object_id('tempdb..#num_keypad_moves') is not null
    drop table #num_keypad_moves;

with
c as
(
    select
        row,
        col,
        convert(varchar(100), num) as path,
        convert(varchar(100), '') as move_path
    from #num_keypad

    union all

    select
        k.row,
        k.col,
        convert(varchar(100), concat(c.path, num)),
        convert(varchar(100), concat(c.move_path, case when k.row = c.row then case when k.col < c.col then '<' else '>' end else case when k.row < c.row then '^' else 'v' end end))
    from c
    inner join #num_keypad as k on
        (k.row = c.row and k.col in (c.col-1, c.col+1))
        or (k.col = c.col and k.row in (c.row-1, c.row+1))
    where
        c.path not like '%'+num+'%'
)
select
    left(c.path, 1) as num_from,
    right(c.path, 1) as num_to,
    min(len(c.path))-1 as distance,
    count(*) as num_paths,
    min(c.move_path) as one_path
into #num_keypad_moves
from c
inner join #num_keypad as k_from on
    k_from.num = left(c.path, 1)
inner join #num_keypad as k_to on
    k_to.num = right(c.path, 1)
where
    len(c.path)-1 = abs(k_from.col - k_to.col)+abs(k_from.row - k_to.row)
group by
    left(c.path, 1),
    right(c.path, 1)
;

if object_id('tempdb..#dir_keypad') is not null
    drop table #dir_keypad;

select
    x.*
into #dir_keypad
from (values (1, 2, '^'),(1, 3, 'A'),(2, 1, '<'),(2, 2, 'v'),(2, 3, '>')) as x (row,col,dir)
;

if object_id('tempdb..#dir_keypad_moves') is not null
    drop table #dir_keypad_moves;

with
c as
(
    select
        row,
        col,
        convert(varchar(100), dir) as path,
        convert(varchar(100), '') as move_path
    from #dir_keypad

    union all

    select
        k.row,
        k.col,
        convert(varchar(100), concat(c.path, dir)),
        convert(varchar(100), concat(c.move_path, case when k.row = c.row then case when k.col < c.col then '<' else '>' end else case when k.row < c.row then '^' else 'v' end end))
    from c
    inner join #dir_keypad as k on
        (k.row = c.row and k.col in (c.col-1, c.col+1))
        or (k.col = c.col and k.row in (c.row-1, c.row+1))
    where
        c.path not like '%'+dir+'%'
)
select
    left(c.path, 1) as dir_from,
    right(c.path, 1) as dir_to,
    min(len(c.path))-1 as distance,
    count(*) as num_paths,
    min(c.move_path) as one_path
into #dir_keypad_moves
from c
inner join #dir_keypad as k_from on
    k_from.dir = left(c.path, 1)
inner join #dir_keypad as k_to on
    k_to.dir = right(c.path, 1)
where
    len(c.path)-1 = abs(k_from.col - k_to.col)+abs(k_from.row - k_to.row)
    and c.move_path <> '>^>'
group by
    left(c.path, 1),
    right(c.path, 1)
;

declare @inner_seq varchar(1000) = 'A' +
    (
        select
            np.one_path + 'A'
        from #num_keypad_moves as np
        inner join
        (
            select
                substring(@num_seq, move+1, 1) as pos,
                lead(substring(@num_seq, move+1, 1)) over (order by move) as next_pos,
                move
            from (values (0),(1),(2),(3),(4)) as m (move)
        ) as seq on
            seq.pos = np.num_from
            and seq.next_pos = np.num_to
        for xml path(''), type
    ).value('.', 'varchar(max)')
;

declare @second_seq varchar(max);

with
a (n) as (select 1 union all select 1),
b (n) as (select x.n from a x, a y),
c (n) as (select x.n from b x, b y),
d (n) as (select x.n from c x, c y),
e (n) as (select x.n from d x, d y),
nums as
(
    select top(len(@inner_seq))
        row_number() over (order by 1/0) - 1 as n
    from e
)
select @second_seq = 'A' +
    (
        select
            dp.one_path + 'A'
        from #dir_keypad_moves as dp
        inner join
        (
            select
                substring(@inner_seq, n+1, 1) as pos,
                lead(substring(@inner_seq, n+1, 1)) over (order by n) as next_pos,
                n
            from nums
        ) as seq on
            seq.pos = dp.dir_from
            and seq.next_pos = dp.dir_to
        for xml path(''), type
    ).value('.', 'varchar(max)');

declare @final_seq varchar(max);

with
a (n) as (select 1 union all select 1),
b (n) as (select x.n from a x, a y),
c (n) as (select x.n from b x, b y),
d (n) as (select x.n from c x, c y),
e (n) as (select x.n from d x, d y),
nums as
(
    select top(len(@second_seq))
        row_number() over (order by 1/0) - 1 as n
    from e
)
select @final_seq =
    (
        select
            dp.one_path + 'A'
        from #dir_keypad_moves as dp
        inner join
        (
            select
                substring(@second_seq, n+1, 1) as pos,
                lead(substring(@second_seq, n+1, 1)) over (order by n) as next_pos,
                n
            from nums
        ) as seq on
            seq.pos = dp.dir_from
            and seq.next_pos = dp.dir_to
        for xml path(''), type
    ).value('.', 'varchar(max)');

select @final_seq, len(@final_seq);
