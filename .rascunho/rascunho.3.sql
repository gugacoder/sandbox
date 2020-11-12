--
-- SCHEMA host
--
if not exists (select 1 from sys.schemas where name = 'host') begin
  exec sp_executesql N'create schema host'
end
go

--
-- FUNCTION host.SPLIT_PART
--
drop function if exists host.SPLIT_PART
go
create function host.SPLIT_PART(
    @string nvarchar(max)
  , @delimitador nvarchar(max)
  , @posicao_do_termo_desejado int)
returns nvarchar(max)
as
begin
  if @string is null return null

  declare @posicao int = 1
  declare @indice int = 1
  declare @termo nvarchar(max)

  while @indice != 0
  begin
    set @indice = charindex(@delimitador, @string)
    if @indice != 0
      set @termo = left(@string, @indice - 1)
    else
      set @termo = @string
    
    if @posicao = @posicao_do_termo_desejado
      return @termo

    set @string = right(@string, len(@string) - @indice - len(@delimitador) + 1)
    if len(@string) = 0
      break

    set @posicao = @posicao + 1
  end
  return null
end
go

--
-- FUNCTION host.SPLIT
--
drop function if exists host.SPLIT  
go
create function host.SPLIT(
    @string nvarchar(max)
  , @delimitador nvarchar(max)
  )
returns @termos table ([indice] int identity(1,1), [valor] nvarchar(max))
as
begin
  if @string is null return

  declare @indice int = 1
  declare @termo nvarchar(max)

  while @indice != 0
  begin
    set @indice = charindex(@delimitador, @string)
    if @indice != 0
      set @termo = left(@string, @indice - 1)
    else
      set @termo = @string
    
    insert into @termos ([valor]) values (@termo)

    set @string = right(@string, len(@string) - @indice - len(@delimitador) + 1)
    if len(@string) = 0
      break
  end
  return
end
go

--
-- TABLE host.TBinstancia
--
if object_id('host.TBinstancia') is null begin
  create table host.TBinstancia (
    DFid_instancia int identity(1,1) primary key,
    DFguid uniqueidentifier not null,
    DFversao varchar(50) not null,
    DFdispositivo nvarchar(255) not null,
    DFip nvarchar(1024) not null,
    DFligado bit not null default (1),
    DFultima_vez_visto datetime not null default (current_timestamp)
  )

  create index ix__host_TBinstancia__DFguid
      on host.TBinstancia (DFguid)
end
go

--
-- TABLE host.TBtrava
--
if object_id('host.TBtrava') is null begin
  create table host.TBtrava (
    DFchave_travada varchar(100) not null primary key,
    DFdata_travamento datetime not null default (current_timestamp),
    DFguid_instancia uniqueidentifier not null
  )
end
go

--
-- TABLE host.TBjob
--
if object_id('host.TBjob') is null begin
  create table host.TBjob (
      DFid_job bigint not null identity(1, 1) primary key
    , DFprocedure varchar(100) not null
    , DFdata_execucao datetime not null default current_timestamp
    , DFagendado int not null default (0)
      -- 0: nao executado
      -- 1: executando
      -- 2: executado
    , DFstatus_execucao int not null default (0)
    , DFguid_instancia_execucao uniqueidentifier null
  )

  create index IX__host_TBjob__DFdata_execucao
      on host.TBjob (DFdata_execucao)

  create index IX__host_TBjob__DFagendado
      on host.TBjob (DFagendado)

  create index IX__host_TBjob__DFstatus_execucao
      on host.TBjob (DFstatus_execucao)

  create index IX__host_TBjob__DFguid_instancia_execucao
      on host.TBjob (DFguid_instancia_execucao)
end

--
-- TABLE host.TBjob_parametro
--
if object_id('host.TBjob_parametro') is null begin
  create table host.TBjob_parametro (
    DFid_job_parametro bigint not null identity(1,1) primary key,
    DFid_job bigint not null
      foreign key references host.TBjob (DFid_job)
           on delete cascade,
    DFchave varchar(100) not null,
    DFvalor sql_variant null
  )

  create index IX__host_TBjob_parametro__DFid_job
      on host.TBjob_parametro (DFid_job)
end

--
-- PROCEDURE host.instalar_modulos
--
drop procedure if exists host.instalar_modulos
go
create procedure host.instalar_modulos
as
begin
  exec host.instalar_modulo_jobtask
end
go

--
-- PROCEDURE host.instalar_modulo_jobtask
--
drop procedure if exists host.instalar_modulo_jobtask
go
create procedure host.instalar_modulo_jobtask
as
begin
  select 'tananana...'
end
go

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
   where sys.objects.name like 'jobtask_%'
)
select concat(esquema,'.',[procedure]) as DFprocedure
     , parametro as DFparametro
     , ordem as DFordem
     , tipo as DFtipo
     , cast(case
          when parametro = '@comando'       and tipo = 'varchar(10)'      then 1
          when parametro = '@cod_empresa'   and tipo = 'int'              then 1
          when parametro = '@id_usuario'    and tipo = 'int'              then 1
          when parametro = '@id_instancia'  and tipo = 'uniqueidentifier' then 1
          when parametro = '@automatico'    and tipo = 'bit'              then 1
          when parametro = '@id_referente' then 1
          else 0
       end as bit) DFvalido
     , case parametro
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
          when '@id_instancia' then
            case when tipo != 'uniqueidentifier'
              then 'O parâmetro '+parametro+' deveria ser definido como uniqueidentifier mas foi definido como '+tipo+'.'
            end
          when '@automatico' then
            case when tipo != 'bit'
              then 'O parâmetro '+parametro+' deveria ser definido como bit mas foi definido como '+tipo+'.'
            end
          when '@id_referente' then null
          else 'O parâmetro '+parametro+' não é suportado.'
       end DFinconsistencia
  from tb_parametros
go

--
-- VIEW host.vw_jobtask
--
drop view if exists host.vw_jobtask
go
create view host.vw_jobtask
as
select DFprocedure
     , cast(max(cast(DFvalido as int)) as bit) as DFvalido
     , cast(max(case DFparametro when '@automatico' then 1 else 0 end) as bit) as DFautomatico
     , cast(max(case DFparametro when '@cod_empresa' then 1 else 0 end) as bit) as DFpor_empresa
  from host.vw_jobtask_parametro
 group by DFprocedure
go

/*
--
-- PROCEDURE host.agendar_job
--
drop procedure if exists host.agendar_job
go
create procedure host.agendar_job
    @data_execucao datetime = null
  , @esquema varchar(100) = null
  , @modulo varchar(100) = null
  , @tarefa varchar(100) = null
  , @id_usuario int = null
  , @cod_empresa int = null
  , @id_referente sql_variant = null
as
begin
  if object_id('tempdb..#___proc_args___') is not null begin
    select @esquema = esquema
         , @modulo  = modulo
         , @tarefa  = tarefa
         , @cod_empresa   = coalesce(@cod_empresa, cod_empresa)
         , @id_usuario    = coalesce(@id_usuario, id_usuario)
         , @id_referente  = coalesce(@id_referente, id_referente)
         , @data_execucao = coalesce(@data_execucao, current_timestamp)
     from #___proc_args___
  end

  if @esquema is null or @modulo is null or @tarefa is null begin
    raiserror ('Os parâmetros @esquema, @modulo e @tarefa devem ser definidos.', 11, 1) with log
    return
  end

  insert into host.TBjob (
      DFesquema
    , DFmodulo
    , DFtarefa
    , DFcod_empresa
    , DFid_usuario
    , DFid_referente
    , DFdata_execucao
  )
  values (
      @esquema
    , @modulo
    , @tarefa
    , @cod_empresa
    , @id_usuario
    , @id_referente
    , coalesce(@data_execucao, current_timestamp)
  )
end
go

--
-- PROCEDURE host.executar_job
--
drop procedure if exists host.executar_job
go
create procedure host.executar_job
  @esquema varchar(100),
  @modulo varchar(100),
  @tarefa varchar(100),
  -- 'init' ou 'exec'
  @comando varchar(10),
  @cod_empresa int = null,
  @id_usuario int = null,
  @id_referente sql_variant = null,
  @id_instancia uniqueidentifier = null,
  @automatico bit = 0
as
begin
  select @esquema as esquema
       , @modulo as modulo
       , @tarefa as tarefa
       , @cod_empresa as cod_empresa
       , @id_usuario as id_usuario
       , @id_referente as id_referente
    into #___proc_args___

  declare @sql nvarchar(max) = ''

  select @sql = 'declare @id_referente '+DFtipo+' = cast(@id_referente_original as '+DFtipo+'); '
    from host.vw_jobtask_parametro
   where DFesquema = @esquema
     and DFmodulo = @modulo
     and DFtarefa = @tarefa
     and DFparametro = '@id_referente'
   order by DFordem

  set @sql = @sql + 'exec '+@esquema+'.'+'jobtask__'+@modulo+'__'+@tarefa

  select @sql = @sql + ' ' + DFparametro + ','
    from host.vw_jobtask_parametro
   where DFesquema = @esquema
     and DFmodulo = @modulo
     and DFtarefa = @tarefa
   order by DFordem

  set @sql = left(@sql, len(@sql)-1)
   
  exec sp_executesql
      @sql
    , N'@comando varchar(10)
      , @cod_empresa int
      , @id_usuario int
      , @id_referente_original sql_variant
      , @id_instancia uniqueidentifier
      , @automatico bit'
    , @comando=@comando
    , @cod_empresa=@cod_empresa
    , @id_usuario=@id_usuario
    , @id_referente_original=@id_referente
    , @id_instancia=@id_instancia
    , @automatico=@automatico
end
go
*/

--
-- PROCEDURE host.jobtask_exemplo
--
drop procedure if exists host.jobtask_exemplo
go
create procedure host.jobtask_exemplo
  @comando varchar(10),
  @cod_empresa int = null,
  @id_usuario int = null,
  @id_referente int = null,
  @id_instancia uniqueidentifier = null,
  @automatico bit = 0
as
begin
  -- JOB simples do HOST de serviços.
  --
  -- O JOB tem duas responsabilidades:
  -- 1. Executar sua função como prefereir.
  -- 2. Resultar a data de sua próxima execução.
  --
  -- Nomenclatura
  --    Toda procedure de JOB deve ter uma estrutura rígida de nome
  --    na forma:
  --        [esquema].job__[modulo]__[evento]
  --    O HOST detecta automaticamente procedures com este padrão de nome
  --    e agenda tarefas no seu motor para executá-las.
  --    Exemplos de nomes:
  --        host.job__manutencao__backup_de_12h
  --        -   esquema: host
  --        -   modulo: manutencao
  --        -   evento: backup_de_12h
  --        mlogic.job__carga__enviar_carga
  --        -   esquema: mlogic
  --        -   modulo: carga
  --        -   evento: enviar_carga
  --        dbo.job__sped__nfe_autorizarNfe
  --        -   esquema: dbo
  --        -   modulo: sped
  --        -   evento: nfe_autorizarNfe
  --
  -- Ciclo de Vida
  -- -  init
  --      Na primeira execução a procedure recebe o @comando 'init'.
  --      Neste momento é esperado que a procedure apenas resulte a
  --      data de sua primeira execução.
  -- -  exec
  --      Nas execuções subsequentes a procedure recebe o @comando 'exec'.
  --      Esta é a orgem direta para execução da função da procedure.
  --      Ao final da execução, a procedure pode resultar a data de sua
  --      próxima execução, se quiser ser executada novamente, ou nada
  --      resultar, para não ser mais executada.
  --
  -- Agendamento
  --    O resultado da procedure deve ser: nenhum, para não ser mais executada,
  --    ou a data de sua próxima execução, como uma coluna chamada 'next_run'.
  --
  -- Exemplo
  --    Neste exemplo a procedure é executada em intervalos de 2 segundos:
  --
  --      create procedure dbo.job_exemplo_faz_algo_util
  --        @cod_empresa int,
  --        @comando varchar(10)
  --      as
  --      begin
  --        if @comando = 'exec' begin
  --          ... faz aquilo que deve ser feito ...
  --        end
  --        select dateadd(s, 2, current_timestamp) as next_run
  --      end

  if @comando = 'init' begin
    
    select 1
    -- exec host.agendar_job '2020-12-24'

  end else if @comando = 'exec' begin
    
    print 'ISTO É O ESPERADO A SER FEITO PELA PROCEDURE'

  end

  print concat('@comando: ', @comando)
  print concat('@cod_empresa: ', @cod_empresa)
  print concat('@id_usuario: ', @id_usuario)
  print concat('@id_instancia: ', @id_instancia)
end
go
