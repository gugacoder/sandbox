--
-- PROCEDURE host.jobtask_sample_job
--
drop procedure if exists host.jobtask_sample_job
go
create procedure host.jobtask_sample_job
  @command varchar(10),
  @cod_empresa int = null,
  @id_usuario int = null
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
      @name='emp/{@cod_empresa}',
      @procid=@@procid,
      @due_date=@data,
      @args=@args,
      @description='Exemplo de JOB para a empresa {@cod_empresa}'

  end if @command = 'exec' begin

    raiserror ('EXEC: @cod_empresa: %d, @id_usuario: %d',10,1,@cod_empresa,@id_usuario) with nowait

  end
end
go
