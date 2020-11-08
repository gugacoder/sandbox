
-- exec mlogic.replicar_tabelas_mercadologic 7

-- select count(*) from mlogic.vw_replica_evento
-- select count(*) from mlogic.vw_replica_cupomfiscal
-- select count(*) from mlogic.vw_replica_itemcupomfiscal

/*
What is a JOB?
  A JOB is somewhat like a procedure ran on a schedule.
What does a JOB have?
  A JOB has a schedule
  A JOB has logging information
What must a JOB have?
  A JOB must have an audit mechanism
*/

/*
job.TBjob
job.TBjob_auditoria
job.job_exemplo @cod_empresa @comando @id_job*
  -> @comando
  <- @comando[]
*/


/*
--
-- FUNCTION job.task
--
if object_id('job.TBjob') is null
  create table job.TBjob (
    DFid_job bigint not null identity(1,1)
      constraint PK_job_TBjob primary key,
    DFcod_empresa int not null
      constraint FK_job_TBjob_TBempresa
      references TBempresa (DFcod_empresa)
              on delete cascade,
    DFid_referente int null,
  )

  create index IX_job_TBjob_DFcod_empresa on job.TBjob(DFcod_empresa)
  create index IX_job_TBjob_DFid_referente on job.TBjob(DFid_referente)  
go

--
-- FUNCTION job.args
--
if type_id('job.args') is null
  create type job.args as table (
    chave varchar(100) primary key,
    valor sql_variant
  )
go

--
-- FUNCTION job.audit
--
if type_id('job.audit') is null
  create type job.audit as table (
    id int primary key identity(1,1),
    origem varchar(100),
    evento varchar(100),
    mensagem varchar(max)
  )
go

--
-- PROCEDURE job.job_mercadologic_replicar_tabelas
--
drop procedure if exists job.job_mercadologic_replicar_tabelas
go
create procedure job.job_mercadologic_replicar_tabelas
    @cod_empresa int
  , @fase varchar(10)
  , @args job.args readonly
as
begin
  if object_id('job.__info__') is null begin
    create table job.__info__ (
      texto varchar(max)
    )
  end

  if @fase = 'init' begin
    select 'replica', 'init', 'set somenthing to run...'
    return
  end

  if @fase = 'exec' begin
    select 'replica', 'exec', 'put something to run...'
    return
  end

  select 'replica', 'fail', concat('unrecognizable stage: ', @fase)
end
go

-- Testando...
declare @args job.args
declare @audit job.audit

insert into @args (chave, valor) values ('id', 10)
insert into @args (chave, valor) values ('name', 'Tenth')
insert into @args (chave, valor) values ('age', 1000)

insert into @audit exec job.job_mercadologic_replicar_tabelas 7, 'init', @args
insert into @audit exec job.job_mercadologic_replicar_tabelas 7, 'exec', @args
insert into @audit exec job.job_mercadologic_replicar_tabelas 7, 'done', @args

select * from @audit



*/


--
-- SCHEMA host
--
if not exists (select 1 from sys.schemas where name = 'host') begin
  exec sp_executesql N'create schema host'
end
go

--
-- TABELA host.instance
--
if object_id('host.instance') is null begin
  create table host.instance (
    [id] int identity(1,1)
      constraint pk__host_instance
      primary key,
    [guid] uniqueidentifier not null,
    [revision] varchar(50) not null,
    [device] nvarchar(255) not null,
    [ip] nvarchar(1024) not null,
    [started] bit not null
      constraint def__host_instance__on
      default (1),
    [last_seen] datetime not null
      constraint def__host_instance__last_seen
      default (current_timestamp)
  )

  create index ix__host_instance__guid
      on host.instance ("guid")
end
go

--
-- TABELA host.locking
--
if object_id('host.locking') is null begin
  create table host.locking (
    [key] varchar(100) not null
      constraint pk__host_locking
      primary key,
    [at] datetime not null
      constraint def__host_locking__at
      default (current_timestamp),
    [instance_guid] uniqueidentifier not null
  )
end
go



--
-- PROCEDURE host.jobtask__sandbox__exemplo_de_evento
--
drop procedure if exists dbo.jobtask__sandbox__exemplo_de_evento
go
create procedure dbo.jobtask__sandbox__exemplo_de_evento
  @comando varchar(10),
  @cod_empresa int = null,
  @id_usuario int = null,
  @id_instancia uniqueidentifier = null
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

  if @comando = 'exec' begin
    print 'ISTO É O ESPERADO A SER FEITO PELA PROCEDURE'
  end

  select dateadd(s, 2, current_timestamp) as next_run

  print concat('@comando: ', @comando)
  print concat('@cod_empresa: ', @cod_empresa)
  print concat('@id_usuario: ', @id_usuario)
  print concat('@id_instancia: ', @id_instancia)
end
go

declare @guid uniqueidentifier = newid()
exec dbo.jobtask__sandbox__exemplo_de_evento 'init', 7, null, @guid
-- exec dbo.job__modulo__evento @guid, 'exec', 7

select DBmercadologic.replica.SPLIT_PART(name, '__', 2) as DFmodulo
     , DBmercadologic.replica.SPLIT_PART(name, '__', 4) as DFevento
  from sys.objects
 where name like 'jobtask[_][_]%[_][_]%'


/*
exec replica.replicar_mercadologic 7
exec replica.replicar_mercadologic_eventos 7
exec replica.clonar_tabelas_monitoradas_mercadologic 7
exec replica.replicar_mercadologic_eventos 7
exec replica.replicar_mercadologic_tabelas_pendentes 7
-- delete from replica.evento
select top 10 * from replica.vw_evento
select * from replica.formapagamentoefetuada
select * from replica.exemplo
inner join replica.vw_evento on vw_evento.id_evento = cupomfiscal.id_evento

select * from DBdirector_MAC_29.mlogic.vw_replica_formapagamentoefetuada_historico
*/

/*
drop table replica.cupomfiscal
drop table replica.itemcupomfiscal
drop table replica.formapagamentoefetuada
exec sp_executesql N'
  use DBdirector_mac_29
  drop view mlogic.vw_replica_cupomfiscal
  drop view mlogic.vw_replica_itemcupomfiscal
  drop view mlogic.vw_replica_formapagamentoefetuada
'
-- drop table replica.evento
*/



