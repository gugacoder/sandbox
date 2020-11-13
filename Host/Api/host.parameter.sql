if type_id('[host].[parameter]') is null begin
  create type [host].[parameter] as table (
    [name] varchar(100) primary key,
    [value] sql_variant,
    [order] int identity(1,1),
    [type] as 
      case cast(sql_variant_property([value], 'BaseType') as varchar(100))
         when 'char' then concat('char(',cast(sql_variant_property([value], 'MaxLength') as int),')')
         when 'nchar' then concat('nchar(',cast(sql_variant_property([value], 'MaxLength') as int)/2,')')
         when 'varchar' then concat('varchar(',cast(sql_variant_property([value], 'MaxLength') as int),')')
         when 'nvarchar' then concat('nvarchar(',cast(sql_variant_property([value], 'MaxLength') as int)/2,')')
         when 'decimal' then concat('decimal(',cast(sql_variant_property([value], 'Precision') as int),',',cast(sql_variant_property([value], 'Scale') as int),')')
         when 'numeric' then concat('numeric(',cast(sql_variant_property([value], 'Precision') as int),',',cast(sql_variant_property([value], 'Scale') as int),')')
         else cast(sql_variant_property([value], 'BaseType') as varchar(100))
      end
  )
end
go
