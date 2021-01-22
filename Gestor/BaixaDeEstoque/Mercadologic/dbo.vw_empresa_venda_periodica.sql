drop view if exists dbo.vw_empresa_venda_periodica
go
create view dbo.vw_empresa_venda_periodica
as
select DFcod_empresa
       -- TODO: Como determinar se a baixa de estoque peri�dica est� ativada?
       --       Deveria haver uma op��o na TBopcoes?
       --       Ou alguma configura��o adicional?
     , case when DFdata_inativacao is null
         then cast(1 as bit)
         else cast(0 as bit)
       end as DFvenda_periodica_ativada
  from director.TBempresa
go
select * from dbo.vw_empresa_venda_periodica
