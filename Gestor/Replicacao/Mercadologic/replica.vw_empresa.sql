--
-- VIEW replica.vw_empresa
--
create or alter view replica.vw_empresa
as 
select *
     , cast(null as datetime) as DFreplicacao_desativado
  from {ScriptPack.Director}.dbo.TBempresa_mercadologic
go



