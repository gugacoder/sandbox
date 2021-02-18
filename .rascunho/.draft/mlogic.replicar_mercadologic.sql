--
-- PROCEDURE mlogic.replicar_mercadologic
--
drop procedure if exists mlogic.replicar_mercadologic
go
create procedure mlogic.replicar_mercadologic (
    @cod_empresa int
  , @maximo_de_registros int = null
) as
begin
  exec {ScriptPack.Mercadologic}.replica.replicar_mercadologic
    @cod_empresa=@cod_empresa,
    @maximo_de_registros=@maximo_de_registros
end
go
