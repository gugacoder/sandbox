--
-- VIEW replica.vw_empresa
--
create or alter view replica.vw_empresa
as 
select * from {ScriptPack.Director}.dbo.TBempresa_mercadologic
go



