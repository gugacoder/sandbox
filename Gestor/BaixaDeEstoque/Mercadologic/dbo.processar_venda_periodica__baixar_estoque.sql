drop procedure if exists mlogic.processar_venda_periodica__baixar_estoque
go
create procedure mlogic.processar_venda_periodica__baixar_estoque (
    @cod_empresa int = null
) as
  --
  --  Realiza a baixa de estoque a partir da venda periódica.
  --
begin

  select 'Em construção...'

end
