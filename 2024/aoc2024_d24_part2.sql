/*
And after the "not very difficult" Part 1, the hammer drops...

Getting started took some thought, but at some point I decided to manually add up the two input
numbers and compare the resultant bits to the output. This told me (for my input) that the errors
were all fairly high (starting at bit 8), so I knew that I could trust the first few cycles.

Given the above I went ahead and analyzed the input program, tracing things until I arrived at the
appropriate "recipe" for each output bit. (See analysis below.) Then I wrote some code to detect
errors at each stage.

At this point I was not really in the mood to further automate things, especially since I only needed
to find 4 anomalies -- so I simply ran the program, manually fixed the first error in the input, ran it
again, fixed the second error, and so on, until I got a clean result.
*/

declare @in nvarchar(max) = N'x00: 0
x01: 1
x02: 0
x03: 1
x04: 0
x05: 1
y00: 0
y01: 0
y02: 1
y03: 1
y04: 0
y05: 1

x00 AND y00 -> z05
x01 AND y01 -> z02
x02 AND y02 -> z01
x03 AND y03 -> z03
x04 AND y04 -> z04
x05 AND y05 -> z00';

if object_id('tempdb..#bits') is not null
    drop table #bits;

select
    convert(int, 1) as stage,
    convert(varchar(10), left(s.value, charindex(':', s.value)-1)) as register,
    convert(int, right(s.value, 1)) as value
into #bits
from string_split(replace(@in, char(10), ''), char(13)) as s
where
    s.value like '%:%';

create clustered index sr on #bits (stage, register);
create index r on #bits (register);

if object_id('tempdb..#operations') is not null
    drop table #operations;

select
    i1.input1,
    i2.input2,
    p.operation,
    substring(s.value, charindex('>', s.value) + 2, len(s.value)) as destination
into #operations
from string_split(replace(@in, char(10), ''), char(13)) as s
cross apply
(
    values (left(s.value, charindex(' ', s.value)))
) as i1(input1)
cross apply
(
    values (trim(substring(s.value, len(i1.input1) + 1, charindex(' ', s.value, len(input1) + 1))))
) as p (operation)
cross apply
(
    values (trim(substring(s.value, len(i1.input1)+len(p.operation)+2, charindex(' ', s.value, len(i1.input1)+len(p.operation)+2) - 3)))
) as i2(input2)
where
    s.value like '%>%';

declare @s int = 1;

while 1=1
begin
    insert into #bits
    select
        @s + 1,
        ox.destination,
        case ox.operation when 'AND' then v1 & v2 when 'OR' then v1 | v2 else v1 ^ v2 end
    from
    (
        select distinct
            case when b.register < b1.register then b.value else b1.value end as v1,
            case when b.register < b1.register then b1.value else b.value end as v2,
            o.destination,
            o.operation
        from #bits as b
        inner join #operations as o on
            b.register in (o.input1, o.input2)
        cross apply
        (
            select
                bx0.value,
                bx0.register
            from #bits as bx0
            where
                o.input1 = b.register
                and o.input2 = bx0.register
            union all
            select
                bx1.value,
                bx1.register
            from #bits as bx1
            where
                o.input2 = b.register
                and o.input1 = bx1.register
        ) as b1
        where
            b.stage = @s
    ) as ox;

    if @@rowcount = 0
        break;

    set @s += 1;
end;

-- Find the bad bits
select
    f.b as bit, f.val as two_power, f.value as incorrect_value
from
(
    select
        sum(power(convert(bigint, 2), right(register, 2)) * value) as expected
    from #bits
    where
        stage = 1
) as e
cross join
(
    select
        right(register, 2) as b,
        power(convert(bigint, 2), right(register, 2)) as val,
        value
    from #bits
    where
        register like 'z%'
) as f
where
    1 =
        case
            when f.value = 0 then
                case
                    when e.expected | f.val = e.expected then 1
                    else 0
                end
            else
                case
                    when e.expected | f.val <> e.expected then 1
                else 0
            end
        end;

/*
Analysis...

--------------------------
For all x > 1:

x[n] & y[n] -> a[n]          --stage 2 (always)
x[n] ^ y[n] -> b[n]          --stage 2 (always)

d[n-1] & b[n] -> c[n]        --stage n*2 + 1
d[n-1] ^ b[n] -> z[n]        --stage n*2 + 1

a[n] | c[n] -> d[n]          --stage n*2 + 2
--------------------------
*/

--Assume the first couple of stages are okay...
--d[n-1] --> FOR MY INPUT
declare @d char(3) = 'gbg';
declare @n int = 2;

--Walk the rest of the stages and validate all of the expected bits
while @n <= 44
begin
    declare @a char(3), @b char(3);

    select
        @a = min(case operation when 'AND' then destination else null end),
        @b = min(case operation when 'XOR' then destination else null end)
    from
    (
        select
            case when input2 < input1 then input2 else input1 end as i1,
            case when input1 < input2 then input2 else input1 end as i2,
            operation,
            destination
        from #operations as o
        inner join #bits on #bits.register = o.destination
        where
            #bits.stage = 2
    ) as y
    where
        i1 = 'x' + right(concat('00', @n), 2);

    declare @c char(3), @z char(3);
    declare @i1_var_c char(3), @i1_var_z char(3), @i2_var_c char(3), @i2_var_z char(3);

    select
        @c = min(case operation when 'AND' then destination else null end),
        @z = min(case operation when 'XOR' then destination else null end),
        @i1_var_c = min(case operation when 'AND' then i1 else null end),
        @i1_var_z = min(case operation when 'XOR' then i1 else null end),
        @i2_var_c = min(case operation when 'AND' then i2 else null end),
        @i2_var_z = min(case operation when 'XOR' then i2 else null end)
    from
    (
        select
            case when input2 < input1 then input2 else input1 end as i1,
            case when input1 < input2 then input2 else input1 end as i2,
            operation,
            destination
        from #operations as o
        inner join #bits on #bits.register = o.destination
        where
            #bits.stage = @n*2 + 1
    ) as y;

    declare
        @i1 char(3) = case when @b < @d then @b else @d end, 
        @i2 char(3) = case when @b < @d then @d else @b end;

    if @i1 <> @i1_var_c
        raiserror('i1 not correct for var c - n: %i; i1: %s; i1_c: %s', 16, 1, @n, @i1, @i1_var_c);
    if @i2 <> @i2_var_c
        raiserror('i2 not correct for var c - n: %i; i2: %s; i2_c: %s', 16, 1, @n, @i2, @i2_var_c);
    if @i1 <> @i1_var_z
        raiserror('i1 not correct for var z - n: %i; i1: %s; i1_z: %s', 16, 1, @n, @i1, @i1_var_z);
    if @i2 <> @i2_var_z
        raiserror('i2 not correct for var z - n: %i; i2: %s; i2_z: %s', 16, 1, @n, @i2, @i2_var_z);
    if @c like 'z%'
        raiserror('sus c value: %s; n: %i', 16, 1, @c, @n);
    if @z <> 'z'+right(concat('00', @n), 2)
        raiserror('incorrect z: %s; n: %i', 16, 1, @z, @n);

    declare @i1_var_d char(3), @i2_var_d char(3);

    select
        @i1_var_d = case when input2 < input1 then input2 else input1 end,
        @i2_var_d = case when input1 < input2 then input2 else input1 end,
        @d = destination
    from #operations as o
    inner join #bits on #bits.register = o.destination
    where
        #bits.stage = @n*2 + 2;

    select
        @i1 = case when @a < @c then @a else @c end,
        @i2 = case when @a < @c then @c else @a end;

    if @i1 <> @i1_var_d
        raiserror('i1 not correct for var d - n: %i; i1: %s; i1_d: %s', 16, 1, @n, @i1, @i1_var_d);
    if @i2 <> @i2_var_d
        raiserror('i2 not correct for var d - n: %i; i2: %s; i2_d: %s', 16, 1, @n, @i2, @i2_var_d);

    set @n = @n + 1
end;
