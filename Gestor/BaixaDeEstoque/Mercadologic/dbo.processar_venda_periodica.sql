drop procedure if exists processar_venda_periodica
go
create procedure processar_venda_periodica (
    @cod_empresa int = null
  , @id_usuario int = null
  , @id_formulario int = 0
) as
  --
  --  Procedimento de importa��o da venda peri�dica do PDV.
  --
begin

  if @id_usuario is null begin
    select @id_usuario = min(DFid_usuario)
      from director.TBusuario with (nolock)
     where DFnivel_usuario = 99
  end

  --  1.  Sumarizar a venda do item replicada do PDV uma venda peri�dica;
  exec processar_venda_periodica__gerar_venda_periodica @cod_empresa, @id_usuario, @id_formulario

  --  2.  Baixar o estoque a partir da venda peri�dica;
  exec processar_venda_periodica__baixar_estoque @cod_empresa, @id_usuario, @id_formulario

  --  3.  Atualizar a venda di�ria marconda-a como j� atualizada;
  exec processar_venda_periodica__gerar_venda_diaria @cod_empresa, @id_usuario, @id_formulario

  --  4.  Apagar dados hist�ricos da venda peri�dica;
  exec processar_venda_periodica__limpar_historico @cod_empresa, @id_usuario, @id_formulario

end

go

-- exec processar_venda_periodica
