--
-- PROCEDURE replica.jobtask_replicar_mercadologic
--
drop procedure if exists replica.jobtask_replicar_mercadologic
go
create procedure replica.jobtask_replicar_mercadologic
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
      from director.TBempresa with (nolock)
     where DFdata_inativacao is null
    
    -- Criando um JOB para cada lote de parametros.
    exec host.do_schedule_job
      @name='job.empresa.{@cod_empresa}',
      @procid=@@procid,
      --  Dias da semana:
      --      1   domingo
      --      2   segunda
      --      4   terça
      --      8   quarta
      --      16  quinta
      --      32  sexta
      --      64  sábado
      --  Escolha os dias de execução do JOB e some os números correspondentes.
      --  Por exemplo, para executar o JOB...
      --      Todos os dias some todos os números, portanto: 127;
      --      Dias de semana some os dias úteis, portanto: 62;
      --      Fins de semana some sábado e domingo, portanto: 65;
      @days=127,
      --  Hora ou intervalo de execução, dependendo da configuração do parâmetro @repeat.
      @time='00:00:02',
      --  Determina como a hora configurada em @time deve ser interpretada:
      --      Quando `0` a hora corresponde à hora do dia em que o JOB deve ser executado.
      --          Por exemplo, se @time vale `12:00:00` então o JOB é executado sempre
      --          ao meio dia.
      --      Quando `1` a hora corresponde ao intervalo de execução do JOB ao longo do dia
      --          Por exemplo, se @time vale `12:00:00` o JOB é executado de 12 em 12 horas.
      @repeat=1,
      --  Quando @repeat vale 1 o parâmetro @time é interpretado como um intervalo de
      --  execução do JOB. Neste caso @delayed determina como esse intervalo deve ser
      --  interpretado.
      --      Quando `0` o JOB é executado a cada X segundos.
      --      Quando `1` o JOB é executado depois de decorridos X segundos da sua
      --      execução anterior.
      --  Quanto @repeat vale 0 este parâmetro é desconsiderado.
      @delayed=1,
      @args=@args,
      @description='JOB de replicação de tabelas da empresa {@cod_empresa}'

  end if @command = 'exec' begin

    begin try
      exec replica.replicar_mercadologic @cod_empresa=@cod_empresa
    end try begin catch
      declare @message nvarchar(max) = concat(error_message(),' (linha ',error_line(),')')
      raiserror (@message,10,1) with nowait
    end catch

  end
end
go
