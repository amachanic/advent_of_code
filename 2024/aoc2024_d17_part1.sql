/*
This one would have been fun..! Implement a simple assembly sort of language. I spent around
15 minutes writing the code and then over an hour trying to understand why it wasn't working.
Turns out my reading comprehension was bad and I misinterpreted a small detail. Always the
little things.
*/

declare @n nvarchar(max) = N'Register A: 729
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0'

if object_id('tempdb..#raw') is not null
    drop table #raw;

select
    s.value,
    row_number() over (order by 1/0) as r
into #raw
from string_split(replace(@n, char(10), ''), char(13)) as s;

declare @separator bigint = (select r from #raw where value = '');

declare @register_a bigint, @register_b bigint, @register_c bigint;

select
    @register_a = min(case when register = 'Register A' then val else null end),
    @register_b = min(case when register = 'Register B' then val else null end),
    @register_c = min(case when register = 'Register C' then val else null end)
from
(
    select
        left(value, charindex(':', value) - 1) as register,
        convert(bigint, substring(value, charindex(':', value) + 2, len(value))) as val
    from #raw
    where r < @separator
) as x;

if object_id('tempdb..#ops') is not null
    drop table #ops;

select
    s.value as op,
    row_number() over (order by 1/0) - 1 as ptr
into #ops
from #raw
cross apply string_split(substring(value, charindex(':', value) + 2, len(value)), ',') as s
where r = @separator + 1;

create clustered index o on #ops (ptr);

if object_id('tempdb..#output') is not null
    drop table #output;

create table #output
(
    pos bigint identity(1,1) not null,
    val bigint not null
);

declare @ptr bigint = 0;

while 1=1
begin
    declare @opcode bigint, @operand bigint;
    select
        @opcode = min(case when ptr = @ptr then op else null end),
        @operand = min(case when ptr = @ptr + 1 then op else null end)
    from #ops
    where
        ptr between @ptr and @ptr + 1;

    if @opcode is null
        break;

    if @operand = 7
        raiserror('invalid operand at ptr %i', 16, 0, @ptr);

    set @operand = case when @opcode = 1 then @operand else case @operand when 4 then @register_a when 5 then @register_b when 6 then @register_c else @operand end end;

    if @opcode in (0, 6, 7)
    begin
        declare @div_result bigint = @register_a / power(2, @operand);
        if @opcode = 0
            set @register_a = @div_result;
        else if @opcode = 6
            set @register_b = @div_result;
        else
            set @register_c = @div_result;
    end;
    else if @opcode = 1
    begin
        set @register_b = @register_b ^ @operand;
    end;
    else if @opcode = 2
    begin
        set @register_b = @operand % 8;
    end;
    else if @opcode = 3
    begin
        if @register_a <> 0
        begin
            set @ptr = @operand;
            continue;
        end;
    end;
    else if @opcode = 4
    begin
        set @register_b = @register_b ^ @register_c;
    end;
    else if @opcode = 5
    begin
        declare @output_result bigint = @operand % 8;
        insert #output (val) values (@output_result);
    end;
    else
        raiserror('invalid opcode at ptr %i - %i', 16, 0, @ptr, @opcode);

    set @ptr += 2;
end;

select
    stuff
    (
        (
            select concat(',', val) from #output
            for xml path(''), type
        ).value('.', 'nvarchar(max)'),
        1,
        1,
        ''
    );

