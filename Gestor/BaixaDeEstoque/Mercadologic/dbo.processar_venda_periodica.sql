drop procedure if exists processar_venda_periodica
go
create procedure processar_venda_periodica (
    @cod_empresa int
  , @id_usuario int = null
  , @id_formulario int = 0
  --
  -- Ativa a valida��o de agendamento do processo.
  -- Se ativado a procedure ir� checar o agendamento da tarefa n�o executando
  -- o procedimento se o intervalo desde a �ltima execu��o for menor que o
  -- configurado.
  , @honrar_agendamento bit = 0
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

  --
  -- Checando parametros...
  --
  declare @venda_periodica_ativada bit
  
  select @venda_periodica_ativada = DFvenda_periodica_ativada
    from dbo.vw_empresa_venda_periodica with (nolock)
   where DFcod_empresa = @cod_empresa

  if @venda_periodica_ativada != 1 begin
    raiserror ('[NOTA]: A venda peri�dica n�o est� ativada para a empresa %d.',10,1,@cod_empresa)
    return
  end

  --
  -- Checando agendamento...
  --
  if @honrar_agendamento = 1 begin

    declare @intervalo datetime
    declare @ultima_execucao datetime
    declare @proxima_execucao datetime

    select @intervalo = DFintervalo_processamento
      from dbo.vw_empresa_venda_periodica
     where DFcod_empresa = @cod_empresa

    select @ultima_execucao = max(DFdata_execucao)
      from dbo.TBvenda_periodica_auditoria
     where DFcod_empresa = @cod_empresa

    set @proxima_execucao = case
          when @ultima_execucao is null then current_timestamp
          else @ultima_execucao + @intervalo
        end

    if @proxima_execucao > current_timestamp begin
      raiserror ('[NOTA]: Ainda n�o est� na ora de processar a venda peri�dica da empresa %d.',10,1,@cod_empresa)
      return
    end 
  end
  
  --
  -- Auditando...
  --
  insert into TBvenda_periodica_auditoria (
      DFcod_empresa, DFdata_execucao, DFid_usuario, DFid_formulario)
  select @cod_empresa, current_timestamp, @id_usuario, @id_formulario

  --
  -- Procedendo...
  --

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

exec processar_venda_periodica 7, @honrar_agendamento=1
-- select * from TBvenda_periodica_auditoria 
