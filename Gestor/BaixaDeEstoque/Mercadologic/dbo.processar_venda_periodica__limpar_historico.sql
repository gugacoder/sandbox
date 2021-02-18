drop procedure if exists processar_venda_periodica__limpar_historico
go
create procedure processar_venda_periodica__limpar_historico (
    @cod_empresa int
  , @id_usuario int
  , @id_formulario int
) as
  --
  --  Apaga dados históricos da venda periódica.
  --
begin

  begin try
    begin transaction tx
  
    -- TODO: A data limite para armazenagem do histórido da venda peródica
    -- deveria ser configurável? se sim onde?
    -- Por enquanto estamos mantendo 6 meses.
    declare @data_historica datetime = dateadd(d, -6*30, current_timestamp)

    -- Ajustando a data histórica.
    -- Deve existir um histórico de pelo menos 24 horas porque o algoritmo
    -- depende dessa informação para ajustar o intervalo de execução.
    if @data_historica > dateadd(hh, -24, current_timestamp) begin
      set @data_historica = dateadd(hh, -24, current_timestamp)
    end

    -- Limpando venda periodica
    delete from TBvenda_periodica
     where (@cod_empresa is null or DFcod_empresa = @cod_empresa)
       and DFdata_venda < @data_historica
       and exists (
             select 1 from dbo.vw_empresa_venda_periodica
              where DFcod_empresa = TBvenda_periodica.DFcod_empresa
                and DFvenda_periodica_ativada = 1)
    
    -- Limpando auditoria
    delete from TBvenda_periodica_auditoria
     where DFdata_execucao < @data_historica
      
    commit transaction tx
  end try
  begin catch
    if @@trancount > 0
      rollback transaction tx
      
    declare @mensagem nvarchar(max) = concat(error_message(),' (linha ',error_line(),')')
    declare @severidade int = error_severity()
    declare @estado int = error_state()

    raiserror (@mensagem, @severidade, @estado) with nowait
  end catch
    
end

go

-- processar_venda_periodica__limpar_historico null, 1, 0
