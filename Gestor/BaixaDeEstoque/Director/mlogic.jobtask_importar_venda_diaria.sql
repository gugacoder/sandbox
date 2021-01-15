--
-- PROCEDURE mlogic.jobtask_importar_venda_diaria
--
drop procedure if exists mlogic.jobtask_importar_venda_diaria
go
create procedure mlogic.jobtask_importar_venda_diaria
  @command varchar(10),
  @cod_empresa int = null
as
begin

  if @command = 'init' begin
    -- Agendando este JOB por empresa.

    declare @data datetime = current_timestamp
    declare @args host.tp_parameter

    -- Criando um lote de parametros para cada empresa.
    insert into @args (lot, name, value)
    select DFcod_empresa, '@cod_empresa', DFcod_empresa
      from TBempresa
     where DFdata_inativacao is null
    
    -- Criando um JOB para cada lote de parametros.
    exec host.do_schedule_job
      @name='job.empresa.{@cod_empresa}',
      @procid=@@procid,
      -- Soma dos dias de execução do JOB
      -- Cada dia corresponde a um número, basta somar os dias desejados:
      --    1   domingo
      --    2   segunda
      --    4   terça
      --    8   quarta
      --    16  quinta
      --    32  sexta
      --    64  sábado
      -- Portanto, todos os dias é: 127
      @days=127,
      @time='03:00:00', -- intervalo
      @repeat=1,        -- repetir a cada intervalo
      @delayed=1,       -- após a execução anterior
      @args=@args,
      @description='JOB de baixa automática da venda diária da empresa {@cod_empresa}'

  end if @command = 'exec' begin

    begin try
      exec mlogic.importar_itens_vendidos @cod_empresa=@cod_empresa
      exec mlogic.baixar_estoque_itens_vendidos @cod_empresa=@cod_empresa
    end try begin catch
      declare @message nvarchar(max) = concat(error_message(),' (linha ',error_line(),')')
      raiserror (@message,10,1) with nowait
    end catch

  end
end
go
