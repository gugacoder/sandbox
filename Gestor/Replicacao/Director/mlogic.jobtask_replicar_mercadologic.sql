--
-- PROCEDURE mlogic.jobtask_replicar_mercadologic
--
drop procedure if exists mlogic.jobtask_replicar_mercadologic
go
create procedure mlogic.jobtask_replicar_mercadologic
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
      -- Soma dos dias de execu��o do JOB
      -- Cada dia corresponde a um n�mero, basta somar os dias desejados:
      --    1   domingo
      --    2   segunda
      --    4   ter�a
      --    8   quarta
      --    16  quinta
      --    32  sexta
      --    64  s�bado
      -- Portanto, todos os dias �: 127
      @days=127,
      @time='00:00:02',
      @repeat=1,  -- repetir a cada X horas
      @delayed=1, -- ap�s a execu��o anterior
      @args=@args,
      @description='JOB de replica��o de tabelas da empresa {@cod_empresa}'

  end if @command = 'exec' begin

    begin try
      exec mlogic.replicar_mercadologic @cod_empresa=@cod_empresa
    end try begin catch
      declare @message nvarchar(max) = concat(error_message(),' (linha ',error_line(),')')
      raiserror (@message,10,1) with nowait
    end catch

  end
end
go
