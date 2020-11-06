--
-- PROCEDURE mlogic.replicar_tabelas_mercadologic
--
drop procedure if exists mlogic.replicar_tabelas_mercadologic
go
create procedure mlogic.replicar_tabelas_mercadologic (
    @cod_empresa int
) as
begin
  exec DBmercadologic.replica.replicar_mercadologic @cod_empresa
end
go
