--
-- VIEW host.vw_jobtask_parametro
--
drop view if exists host.vw_jobtask_parametro
go
create view host.vw_jobtask_parametro
as
with tb_parametros as (
  select sys.schemas.name as esquema
       , sys.objects.name as [procedure]
       , sys.parameters.name as parametro
       , case type_name(sys.parameters.user_type_id)
           when 'varchar' then concat('varchar(',sys.parameters.max_length,')')
           when 'decimal' then concat('decimal(',sys.parameters.precision,',',sys.parameters.scale,')')
           else type_name(sys.parameters.user_type_id)
         end tipo
       , sys.parameters.parameter_id as ordem
    from sys.objects
   inner join sys.parameters
           on sys.parameters.object_id = sys.objects.object_id
   inner join sys.schemas
           on sys.schemas.schema_id = sys.objects.schema_id
   where sys.objects.name like 'jobtask__%__%'
)
select esquema as DFesquema
     , host.SPLIT_PART([procedure], '__', 2) as DFmodulo
     , host.SPLIT_PART([procedure], '__', 3) as DFtarefa
     , concat(esquema,'.',[procedure]) as DFprocedure
     , parametro as DFparametro
     , ordem as DFordem
     , tipo as DFtipo
     , cast(case
          when parametro = '@id_job'        and tipo = 'bigint'           then 1
          when parametro = '@comando'       and tipo = 'varchar(10)'      then 1
          when parametro = '@cod_empresa'   and tipo = 'int'              then 1
          when parametro = '@id_usuario'    and tipo = 'int'              then 1
          when parametro = '@instancia'     and tipo = 'uniqueidentifier' then 1
          when parametro = '@automatico'    and tipo = 'bit'              then 1
          when parametro = '@data_execucao' and tipo = 'datetime'         then 1
          when parametro = '@id_referente'  then 1
          else 0
       end as bit) DFvalido
     , case parametro
          when '@id_job' then
            case when tipo != 'bigint'
              then 'O parâmetro '+parametro+' deveria ser definido como varchar(10) mas foi definido como '+tipo+'.'
            end
          when '@comando' then
            case when tipo != 'varchar(10)'
              then 'O parâmetro '+parametro+' deveria ser definido como varchar(10) mas foi definido como '+tipo+'.'
            end
          when '@cod_empresa' then
            case when tipo != 'int'
              then 'O parâmetro '+parametro+' deveria ser definido como int mas foi definido como '+tipo+'.'
            end
          when '@id_usuario' then
            case when tipo != 'int'
              then 'O parâmetro '+parametro+' deveria ser definido como int mas foi definido como '+tipo+'.'
            end
          when '@instancia' then
            case when tipo != 'uniqueidentifier'
              then 'O parâmetro '+parametro+' deveria ser definido como uniqueidentifier mas foi definido como '+tipo+'.'
            end
          when '@automatico' then
            case when tipo != 'bit'
              then 'O parâmetro '+parametro+' deveria ser definido como bit mas foi definido como '+tipo+'.'
            end
          when '@data_execucao' then
            case when tipo != 'datetime'
              then 'O parâmetro '+parametro+' deveria ser definido como bit mas foi definido como '+tipo+'.'
            end
          when '@id_referente' then null
          else 'O parâmetro '+parametro+' não é suportado.'
       end DFinconsistencia
  from tb_parametros
go
