--
-- PROCEDURE mlogic.baixar_estoque_vendido
--
drop procedure if exists mlogic.baixar_estoque_vendido
go
create procedure mlogic.baixar_estoque_vendido (
    @cod_empresa int = null
) as
 --
 -- Baixa o estoque dos itens vendidos nos PDVs disponíveis e pendentes na
 -- tabela de venda diária do DIRECTOR.
 --
begin

  select 'Em construção...'

end
go
