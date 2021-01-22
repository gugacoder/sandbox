drop procedure if exists processar_venda_periodica
go
create procedure processar_venda_periodica (
    @cod_empresa int = null
) as
  --
  --  Procedimento de importa��o da venda peri�dica do PDV.
  --
begin

  --  1.  Sumarizar a venda do item replicada do PDV uma venda peri�dica;
  exec processar_venda_periodica__gerar_venda_periodica  @cod_empresa

  --  2.  Baixar o estoque a partir da venda peri�dica;
  exec processar_venda_periodica__baixar_estoque @cod_empresa

  --  3.  Atualizar a venda di�ria marconda-a como j� atualizada;
  exec processar_venda_periodica__gerar_venda_diaria @cod_empresa

  --  4.  Apagar dados hist�ricos da venda peri�dica;
  exec processar_venda_periodica__limpar_historico @cod_empresa

  select 'Em constru��o...'

end
