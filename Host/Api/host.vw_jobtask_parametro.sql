drop view if exists [host].[vw_jobtask_parameter]
go
create view [host].[vw_jobtask_parameter]
as
with tb_parameters as (
  select sys.schemas.name as [schema]
       , sys.objects.name as [procedure]
       , sys.parameters.name as [parameter]
       , case type_name(sys.parameters.user_type_id)
           when 'char' then concat('char(',sys.parameters.max_length,')')
           when 'nchar' then concat('nchar(',sys.parameters.max_length/2,')')
           when 'varchar' then concat('varchar(',sys.parameters.max_length,')')
           when 'nvarchar' then concat('nvarchar(',sys.parameters.max_length/2,')')
           when 'decimal' then concat('decimal(',sys.parameters.precision,',',sys.parameters.scale,')')
           when 'numeric' then concat('numeric(',sys.parameters.precision,',',sys.parameters.scale,')')
           else type_name(sys.parameters.user_type_id)
         end [type]
       , sys.parameters.parameter_id as [order]
    from sys.objects
   inner join sys.parameters
           on sys.parameters.object_id = sys.objects.object_id
   inner join sys.schemas
           on sys.schemas.schema_id = sys.objects.schema_id
   where sys.objects.name like 'jobtask__%__%'
)
select concat([schema],'.',[procedure]) as [procedure]
     , [parameter] as [name]
     , [order]
     , [type]
     , cast(case
          when [parameter] = '@id_job'        and [type] = 'bigint'           then 1
          when [parameter] = '@comando'       and [type] = 'varchar(10)'      then 1
          when [parameter] = '@cod_empresa'   and [type] = 'int'              then 1
          when [parameter] = '@id_usuario'    and [type] = 'int'              then 1
          when [parameter] = '@instancia'     and [type] = 'uniqueidentifier' then 1
          when [parameter] = '@automatico'    and [type] = 'bit'              then 1
          when [parameter] = '@data_execucao' and [type] = 'datetime'         then 1
          when [parameter] = '@id_referente'  then 1
          else 0
       end as bit) [valid]
     , case [parameter]
          when '@id_job' then
            case when [type] != 'bigint'
              then 'O parâmetro '+[parameter]+' deveria ser definido como varchar(10) mas foi definido como '+[type]+'.'
            end
          when '@comando' then
            case when [type] != 'varchar(10)'
              then 'O parâmetro '+[parameter]+' deveria ser definido como varchar(10) mas foi definido como '+[type]+'.'
            end
          when '@cod_empresa' then
            case when [type] != 'int'
              then 'O parâmetro '+[parameter]+' deveria ser definido como int mas foi definido como '+[type]+'.'
            end
          when '@id_usuario' then
            case when [type] != 'int'
              then 'O parâmetro '+[parameter]+' deveria ser definido como int mas foi definido como '+[type]+'.'
            end
          when '@instancia' then
            case when [type] != 'uniqueidentifier'
              then 'O parâmetro '+[parameter]+' deveria ser definido como uniqueidentifier mas foi definido como '+[type]+'.'
            end
          when '@automatico' then
            case when [type] != 'bit'
              then 'O parâmetro '+[parameter]+' deveria ser definido como bit mas foi definido como '+[type]+'.'
            end
          when '@data_execucao' then
            case when [type] != 'datetime'
              then 'O parâmetro '+[parameter]+' deveria ser definido como bit mas foi definido como '+[type]+'.'
            end
          when '@id_referente' then null
          else 'O parâmetro '+[parameter]+' não é suportado.'
       end [fault]
  from tb_parameters
go
