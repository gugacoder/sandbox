drop function if exists [host].[SQL_VARIANT_NAME]
go
create function [host].[SQL_VARIANT_NAME] (
  @value sql_variant
)
returns varchar(100)
as
begin
  declare
      @type varchar(100) = cast(sql_variant_property(@value, 'BaseType') as varchar(100))
    , @size int = cast(sql_variant_property(@value, 'MaxLength') as int)
    , @precision int = cast(sql_variant_property(@value, 'Precision') as int)
    , @scale int = cast(sql_variant_property(@value, 'Scale') as int)
  return
    case @type
       when 'char' then concat('char(',@size,')')
       when 'nchar' then concat('nchar(',@size/2,')')
       when 'varchar' then concat('varchar(',@size,')')
       when 'nvarchar' then concat('nvarchar(',@size/2,')')
       when 'decimal' then concat('decimal(',@precision,',',@scale,')')
       when 'numeric' then concat('numeric(',@precision,',',@scale,')')
       else @type
    end
end
go

declare @x sql_variant = cast(1.8 as decimal(18,4))
select host.SQL_VARIANT_NAME(@x)

