drop procedure if exists dbo.jobtask_processar_venda_periodica
go
create procedure dbo.jobtask_processar_venda_periodica
  --  Comando repassado pelo executor do JOB
  --  - init
  --      Ordem emitida pelo executor do JOB para a inicialização do JOB.
  --      É esperado que a procedure faça o agendamento do JOB da forma
  --      mais apropriada invocando a procedure `host.do_schedule_job`.
  --    
  --  - exec
  --      Ordem emitida pelo executor do JOB para a execução do JOB.
  --      É esperado que a procedure realize o processamento efetivamente.
  @command varchar(10),
  --  Código da empresa.
  --  Existe apenas durante a execução do JOB (@command='exec').
  @cod_empresa int = null
as
  --
  --  JOB de processamento e baixa periódica da venda replicada dos PDVs.
  --
begin

  if @command = 'init' begin
    -- Agendando este JOB por empresa.
    -- Depois de agendado o executor do JOB irá executar esta procedure com
    -- os parâmetros `@command='exec'` e @cod_empresa preenchido com o código
    -- de cada empresa agendada.

    declare @data datetime = current_timestamp
    declare @args host.tp_parameter

    -- Criando um lote de parametros para cada empresa.
    insert into @args (lot, name, value)
    select DFcod_empresa, '@cod_empresa', DFcod_empresa
      from director.TBempresa
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
      @time='00:01:00', 
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
      @description='JOB de baixa automática da venda periódica da empresa {@cod_empresa}'

  end if @command = 'exec' begin

    begin try
      exec processar_venda_periodica @cod_empresa, @honrar_agendamento=1
    end try begin catch
      declare @message nvarchar(max) = concat(error_message(),' (linha ',error_line(),')')
      raiserror (@message,10,1) with nowait
    end catch

  end
end
go
