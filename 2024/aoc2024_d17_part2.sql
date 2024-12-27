/*
This second part was not really a programming challenge at all. It was more, how do I even get started?

I took a very hard look at the input programs to figure out what they were actually doing, and noticed
that (at least for my input) the exit criteria was based on reducing Register A by a factor of 8 on each
iteration. I also noticed that Register B was what was getting printed. And so I came to the conclusion
first of all, that only those two registers really mattered - and especially the end state of Register A,
so that the program could acutally exit.

From here I decided to just try to get it to generate a single number, via iteration. The last number made
sense here, because the value of Register A would be small (since the program exits when Register A hits 0).
Further iteration can generate subsequent numbers, starting at the back and moving toward the front; and since
we know that the program divides by 8 on each cycle, we can instead multiply when doing things in reverse,
which skips a lot of dead space and lets us actually complete the task in a reasonable timeframe.

This was a very, very satisfying challenge to complete!
*/

declare @n nvarchar(max) = N'Register A: 729
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0'

/*
Analysis of my input:

Walking backward from just before the output step (second to last), we can see that register_b is entirely determined by register_a
register_a, furthermore, is only updated at the very end, and is divided by 8

0,3: @register_a = @register_a / power(2, 3)             --> this determines exit critera -- must be 0 at the end
4,5: @register_b = @register_b ^ @register_c             --> this is what gets printed
1,5: @register_b = @register_b ^ 5
7,5: @register_c = @register_a / power(2, @register_b)
1,1: @register_b = @register_b ^ 1
2,4: @register_b = @register_a % 8
*/

if object_id('tempdb..#raw') is not null
    drop table #raw;

select
    s.value,
    row_number() over (order by 1/0) as r
into #raw
from string_split(replace(@n, char(10), ''), char(13)) as s;

declare @separator bigint = (select r from #raw where value = '');

declare @register_a bigint, @register_b bigint, @register_c bigint;

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

declare @op_no int = (select max(ptr) from #ops);
declare @register_a_start bigint = 0;

while @op_no >= 0
begin
    declare @target_end varchar(1000) = stuff((select concat(',', op) from #ops where ptr >= @op_no for xml path(''), type).value('.', 'nvarchar(max)'), 1, 1, '');
    declare @register_a_init bigint = @register_a_start;

    while @register_a_init < @register_a_start + 1000
    begin
        set @register_a = @register_a_init;

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


        declare @end varchar(max) = stuff
            (
                (
                    select concat(',', val) from #output
                    for xml path(''), type
                ).value('.', 'nvarchar(max)'),
                1,
                1,
                ''
            );

        if @end = @target_end
            break;

        set @register_a_init += 1;
    end;

    select @op_no, @target_end, @register_a_init;

    set @register_a_start = @register_a_init * 8;
    set @op_no -= 1;
end;
