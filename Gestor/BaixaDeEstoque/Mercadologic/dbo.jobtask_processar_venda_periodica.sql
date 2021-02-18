drop procedure if exists dbo.jobtask_processar_venda_periodica
go
create procedure dbo.jobtask_processar_venda_periodica
  --  Comando repassado pelo executor do JOB
  --  - init
  --      Ordem emitida pelo executor do JOB para a inicializa��o do JOB.
  --      � esperado que a procedure fa�a o agendamento do JOB da forma
  --      mais apropriada invocando a procedure `host.do_schedule_job`.
  --    
  --  - exec
  --      Ordem emitida pelo executor do JOB para a execu��o do JOB.
  --      � esperado que a procedure realize o processamento efetivamente.
  @command varchar(10),
  --  C�digo da empresa.
  --  Existe apenas durante a execu��o do JOB (@command='exec').
  @cod_empresa int = null
as
  --
  --  JOB de processamento e baixa peri�dica da venda replicada dos PDVs.
  --
begin

  if @command = 'init' begin
    -- Agendando este JOB por empresa.
    -- Depois de agendado o executor do JOB ir� executar esta procedure com
    -- os par�metros `@command='exec'` e @cod_empresa preenchido com o c�digo
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
      --      4   ter�a
      --      8   quarta
      --      16  quinta
      --      32  sexta
      --      64  s�bado
      --  Escolha os dias de execu��o do JOB e some os n�meros correspondentes.
      --  Por exemplo, para executar o JOB...
      --      Todos os dias some todos os n�meros, portanto: 127;
      --      Dias de semana some os dias �teis, portanto: 62;
      --      Fins de semana some s�bado e domingo, portanto: 65;
      @days=127,
      --  Hora ou intervalo de execu��o, dependendo da configura��o do par�metro @repeat.
      @time='00:01:00', 
      --  Determina como a hora configurada em @time deve ser interpretada:
      --      Quando `0` a hora corresponde � hora do dia em que o JOB deve ser executado.
      --          Por exemplo, se @time vale `12:00:00` ent�o o JOB � executado sempre
      --          ao meio dia.
      --      Quando `1` a hora corresponde ao intervalo de execu��o do JOB ao longo do dia
      --          Por exemplo, se @time vale `12:00:00` o JOB � executado de 12 em 12 horas.
      @repeat=1,
      --  Quando @repeat vale 1 o par�metro @time � interpretado como um intervalo de
      --  execu��o do JOB. Neste caso @delayed determina como esse intervalo deve ser
      --  interpretado.
      --      Quando `0` o JOB � executado a cada X segundos.
      --      Quando `1` o JOB � executado depois de decorridos X segundos da sua
      --      execu��o anterior.
      --  Quanto @repeat vale 0 este par�metro � desconsiderado.
      @delayed=1,
      @args=@args,
      @description='JOB de baixa autom�tica da venda peri�dica da empresa {@cod_empresa}'

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
