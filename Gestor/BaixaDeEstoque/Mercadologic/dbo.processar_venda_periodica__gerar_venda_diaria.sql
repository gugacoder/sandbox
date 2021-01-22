drop procedure if exists mlogic.processar_venda_periodica__gerar_venda_diaria
go
create procedure mlogic.processar_venda_periodica__gerar_venda_diaria (
    @cod_empresa int = null
) as
  --
  --  Atualiza a venda diária a partir da venda periódica depois da baixa
  --  de estoque efetuada.
  --
begin

  select 'Em construção...'

end
