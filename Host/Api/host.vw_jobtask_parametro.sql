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
         -- Contempla versão dos parâmetros em portugês para compatibilidade.
         when [parameter] in ('@command', '@comando')        and [type] != 'varchar(10)'      then 0
         when [parameter] in ('@instance', '@instancia')     and [type] != 'uniqueidentifier' then 0
         when [parameter] in ('@job_id', '@id_job')          and [type] != 'bigint'           then 0
         when [parameter] in ('@due_date', '@data_execucao') and [type] != 'datetime'         then 0
         else 1
       end as bit) [valid]
     , case
         -- Contempla versão dos parâmetros em portugês para compatibilidade.
         when [parameter] in ('@command', '@comando') and [type] != 'varchar(10)'
           then 'O parâmetro '+[parameter]+' deveria ser definido como varchar(10) mas foi definido como '+[type]+'.'
         when [parameter] in ('@instance', '@instancia') and [type] != 'uniqueidentifier'
           then 'O parâmetro '+[parameter]+' deveria ser definido como uniqueidentifier mas foi definido como '+[type]+'.'
         when [parameter] in ('@job_id', '@id_job') and [type] != 'bigint'
           then 'O parâmetro '+[parameter]+' deveria ser definido como bigint mas foi definido como '+[type]+'.'
         when [parameter] in ('@due_date', '@data_execucao') and [type] != 'datetime'
           then 'O parâmetro '+[parameter]+' deveria ser definido como datetime mas foi definido como '+[type]+'.'
       end [fault]
  from tb_parameters
go
