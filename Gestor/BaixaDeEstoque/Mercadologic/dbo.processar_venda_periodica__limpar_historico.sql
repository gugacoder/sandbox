drop procedure if exists mlogic.processar_venda_periodica__limpar_historico
go
create procedure mlogic.processar_venda_periodica__limpar_historico (
    @cod_empresa int = null
) as
  --
  --  Apaga dados hist�ricos da venda peri�dica.
  --
begin

  select 'Em constru��o...'

end
