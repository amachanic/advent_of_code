/*
Another version of a sort of simplified assembly language processor thing.

Not at all difficult but it took me some time to understand the requirements and type everything.
*/

declare @n nvarchar(max) = N'x00: 1
x01: 0
x02: 1
x03: 1
x04: 0
y00: 1
y01: 1
y02: 1
y03: 1
y04: 1

ntg XOR fgs -> mjb
y02 OR x01 -> tnw
kwq OR kpj -> z05
x00 OR x03 -> fst
tgd XOR rvg -> z01
vdt OR tnw -> bfw
bfw AND frj -> z10
ffh OR nrd -> bqk
y00 AND y03 -> djm
y03 OR y00 -> psh
bqk OR frj -> z08
tnw OR fst -> frj
gnj AND tgd -> z11
bfw XOR mjb -> z00
x03 OR x00 -> vdt
gnj AND wpb -> z02
x04 AND y00 -> kjc
djm OR pbm -> qhw
nrd AND vdt -> hwm
kjc AND fst -> rvg
y04 OR y02 -> fgs
y01 AND x02 -> pbm
ntg OR kjc -> kwq
psh XOR fgs -> tgd
qhw XOR tgd -> z09
pbm OR djm -> kpj
x03 XOR y03 -> ffh
x00 XOR y04 -> ntg
bfw OR bqk -> z06
nrd XOR fgs -> wpb
frj XOR qhw -> z04
bqk OR frj -> z07
y03 OR x01 -> nrd
hwm AND bqk -> z03
tgd XOR rvg -> z12
tnw OR pbm -> gnj';

if object_id('tempdb..#bits') is not null
    drop table #bits;

select
    convert(int, 1) as stage,
    convert(varchar(10), left(s.value, charindex(':', s.value)-1)) as register,
    convert(int, right(s.value, 1)) as value
into #bits
from string_split(replace(@n, char(10), ''), char(13)) as s
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
from string_split(replace(@n, char(10), ''), char(13)) as s
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

select
    sum(power(convert(bigint, 2), right(register, 2)) * value)
from #bits
where
    register like 'z%';
