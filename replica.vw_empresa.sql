--
-- VIEW replica.vw_empresa
--
if object_id('replica.vw_empresa') is not null
  drop view replica.vw_empresa
go
create view replica.vw_empresa
as 
select *
    , cast(null as datetime) as DFreplicacao_desativado
from {ScriptPack.Director}.dbo.TBempresa_mercadologic
go



