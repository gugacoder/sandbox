--
-- TYPE host.args
--
if type_id('host.args') is null begin
  create type host.args as table (
    indice int identity(1,1) primary key,
    chave varchar(100) unique,
    valor sql_variant,
    tipo as 
      case cast(sql_variant_property(valor, 'BaseType') as varchar(100))
         when 'char' then concat('char(',cast(sql_variant_property(valor, 'MaxLength') as int),')')
         when 'nchar' then concat('nchar(',cast(sql_variant_property(valor, 'MaxLength') as int)/2,')')
         when 'varchar' then concat('varchar(',cast(sql_variant_property(valor, 'MaxLength') as int),')')
         when 'nvarchar' then concat('nvarchar(',cast(sql_variant_property(valor, 'MaxLength') as int)/2,')')
         when 'decimal' then concat('decimal(',cast(sql_variant_property(valor, 'Precision') as int),',',cast(sql_variant_property(valor, 'Scale') as int),')')
         when 'numeric' then concat('numeric(',cast(sql_variant_property(valor, 'Precision') as int),',',cast(sql_variant_property(valor, 'Scale') as int),')')
         else cast(sql_variant_property(valor, 'BaseType') as varchar(100))
      end
  )
end
go
