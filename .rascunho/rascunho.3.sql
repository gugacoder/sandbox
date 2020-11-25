
select top 4
       replica.cupomfiscal.serieecf
     , replica.sessao.*
  from replica.cupomfiscal
 inner join replica.sessao
         on replica.sessao.id = replica.cupomfiscal.idsessao
 inner join replica.pdv


/*
select top 1 * from replica.caixa
select top 1 * from replica.sessao
select top 1 * from replica.cestabasicacupom
select top 1 * from replica.comprovantenaofiscal
--select top 1 * from replica.correspondentebancario
select top 1 * from replica.cupom_fiscal_eletronico
select top 1 * from replica.dadostefdedicado
select top 1 * from replica.devolucao
select top 1 * from replica.documentonaofiscal
select top 1 * from replica.formapagamentoefetuada
--select top 1 * from replica.inutilizacao_sefaz
select top 1 * from replica.itemcestabasicacupom
select top 1 * from replica.itemcupomfiscal
select top 1 * from replica.item_devolucao
--select top 1 * from replica.itemprevenda
select top 1 * from replica.pagamentotef
--select top 1 * from replica.prevenda
select top 1 * from replica.recargacelular
select top 1 * from replica.reducaoz
select top 1 * from replica.retorno_sefaz
select top 1 * from replica.sangriaefetuada
select top 1 * from replica.suprimento
*/

use DBdirector

select mlogic.vw_replica_evento.acao
     , mlogic.vw_replica_cupomfiscal_historico.*
  from mlogic.vw_replica_cupomfiscal_historico
 inner join mlogic.vw_replica_evento
         on mlogic.vw_replica_evento.id_evento = mlogic.vw_replica_cupomfiscal_historico.id_evento
 where ccf = 60508

select * from mlogic.vw_replica_cupomfiscal

select mlogic.vw_replica_evento.*
     , mlogic.vw_replica_cupomfiscal_historico.*
  from mlogic.vw_replica_cupomfiscal_historico
 inner join mlogic.vw_replica_evento
         on mlogic.vw_replica_evento.id_evento = mlogic.vw_replica_cupomfiscal_historico.id_evento
 where ccf = 62289
