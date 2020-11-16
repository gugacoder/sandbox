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
      @days=127,
      @time='00:00:02',
      @repeat=1,
      @delayed=1,
      @description='JOB de limpeza do histórico de execução.'

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
