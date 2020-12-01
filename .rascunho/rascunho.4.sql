use msdb
exec sp_delete_job @job_name='Processa - Motor de JOBs do Director'
go

use DBdirector

select sys.objects.name
  from sys.objects inner join sys.schemas on sys.schemas.schema_id = sys.objects.schema_id
 where sys.schemas.name = 'mlogic'
   and sys.objects.type in ('U', 'V', 'P', 'FN')
 order by sys.objects.type, sys.objects.name

drop function if exists mlogic.fn_base_mercadologic
drop procedure if exists mlogic.jobtask_replicar_tabelas_mercadologic
drop procedure if exists mlogic.replicar_tabelas_mercadologic
drop view if exists mlogic.vw_replica_evento

go

use DBmercadologic

select sys.objects.name
  from sys.objects inner join sys.schemas on sys.schemas.schema_id = sys.objects.schema_id
 where sys.schemas.name = 'replica'
   and sys.objects.type in ('U', 'V', 'P', 'FN')
 order by sys.objects.type, sys.objects.name


drop function if exists replica.SPLIT
drop function if exists replica.SPLIT_PART
drop procedure if exists replica.clonar_tabela_mercadologic
drop procedure if exists replica.clonar_tabelas_monitoradas_mercadologic
drop procedure if exists replica.executar_sql_remota
drop procedure if exists replica.replicar_mercadologic
drop procedure if exists replica.replicar_mercadologic_eventos
drop procedure if exists replica.replicar_mercadologic_tabela
drop procedure if exists replica.replicar_mercadologic_tabelas
drop procedure if exists replica.replicar_mercadologic_tabelas_pendentes
drop table if exists replica.caixa
drop table if exists replica.cestabasicacupom
drop table if exists replica.cupom_fiscal_eletronico
drop table if exists replica.cupomfiscal
drop table if exists replica.dadostefdedicado
drop table if exists replica.documentonaofiscal
drop table if exists replica.formapagamentoefetuada
drop table if exists replica.itemcestabasicacupom
drop table if exists replica.itemcupomfiscal
drop table if exists replica.pagamentotef
drop table if exists replica.recargacelular
drop table if exists replica.reducaoz
drop table if exists replica.retorno_sefaz
drop table if exists replica.sangriaefetuada
drop table if exists replica.sessao
drop table if exists replica.suprimento
drop table if exists replica.evento
drop table if exists replica.texto
drop view if exists replica.vw_caixa
drop view if exists replica.vw_cestabasicacupom
drop view if exists replica.vw_cupom_fiscal_eletronico
drop view if exists replica.vw_cupomfiscal
drop view if exists replica.vw_dadostefdedicado
drop view if exists replica.vw_documentonaofiscal
drop view if exists replica.vw_empresa
drop view if exists replica.vw_evento
drop view if exists replica.vw_formapagamentoefetuada
drop view if exists replica.vw_itemcestabasicacupom
drop view if exists replica.vw_itemcupomfiscal
drop view if exists replica.vw_pagamentotef
drop view if exists replica.vw_recargacelular
drop view if exists replica.vw_reducaoz
drop view if exists replica.vw_retorno_sefaz
drop view if exists replica.vw_sangriaefetuada
drop view if exists replica.vw_sessao
drop view if exists replica.vw_suprimento
drop type if exists replica.tp_id
drop schema replica
