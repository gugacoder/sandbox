--
-- PROCEDURE host.jobtask_history_cleanup
--
drop procedure if exists host.jobtask_history_cleanup
go
create procedure host.jobtask_history_cleanup
  @command varchar(10)
as
begin

  if @command = 'init' begin
    
    -- Agendando o job
    exec host.do_schedule_job
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
      @time='00:00:02',
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
      @description='JOB de limpeza do hist�rico de execu��o.'

  end if @command = 'exec' begin

    declare @max_count_per_job int = 10000

    delete host.job_history
      from host.job_history
     inner join (
        select host.job_history.id
             , host.job.[procedure]
             , row_number() over (
                 partition by host.job.[procedure]
                 order by host.job_history.[id] desc
               ) as [row]
          from host.job_history
         inner join host.job
                 on host.job.id = host.job_history.job_id
      ) as t
        on t.id = host.job_history.id
     where [row] > @max_count_per_job

  end
end
go
