
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

declare @id_referente int = cast(@id_referente_original as int); exec host.jobtask__sandbox__exemplo_de_evento @comando, @cod_empresa, @id_usuario, @id_referente, @id_instancia, @automatico
*/
exec host.executar_job
    @esquema='host'
  , @modulo='sandbox'
  , @tarefa='exemplo_de_evento'
  , @comando='init'
  , @cod_empresa=1
  , @id_usuario=1
  , @id_referente=15

--exec host.jobtask__sandbox__exemplo_de_evento 'init', 7, @automatico=1
--select * from host.TBjob

--select * from host.vw_jobtask
--select * from host.vw_jobtask_parametro


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



