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
    select DFcod_empresa, '@cod_empresa', DFcod_empresa from TBempresa
    
    -- Criando um JOB para cada lote de parametros.
    exec host.do_schedule_job
      @name='job.empresa.{@cod_empresa}',
      @procid=@@procid,
      @days=127,
      @time='00:00:02',
      @repeat=1,
      @delayed=1,
      @args=@args,
      @description='JOB de replicação de tabelas da empresa {@cod_empresa}'

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
