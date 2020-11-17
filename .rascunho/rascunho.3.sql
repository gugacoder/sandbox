

select
(select count(1) from mlogic.vw_replica_cupomfiscal with (nolock) where dataabertura > '2020-11-14') as [(3889) cupomfiscal],
(select count(1) from mlogic.vw_replica_itemcupomfiscal with (nolock) where idcupomfiscal in(
    select id 
    from mlogic.vw_replica_cupomfiscal with (nolock)
    where dataabertura > '2020-11-14'
)) as [(37755) itemcupomfiscal],
(select count(1) from mlogic.vw_replica_formapagamento with (nolock)) as [(12) formapagamento],
(select count(1) from mlogic.vw_replica_formapagamentoefetuada with (nolock) where idcupom in(
    select id 
    from mlogic.vw_replica_cupomfiscal with (nolock)
    where dataabertura > '2020-11-14'
)) as [4043 (formapagamentoefetuada)]

-- cupomfiscal  itemcupomfiscal   formapatamento  formapagamentoefetuada
-- 3889         37755	            12	            4043


select * from mlogic.vw_replica_cupomfiscal


set nocount on
exec mlogic.replicar_tabelas_mercadologic 4
;
