--
-- VIEW replica.vw_empresa
--
create or alter view replica.vw_empresa
as 
select * from DBdirector_mac_29.dbo.TBempresa_mercadologic
go
