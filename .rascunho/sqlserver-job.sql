use msdb
go

declare @status int = 0
declare @job_id binary(16)

begin transaction tx

--
-- Garantindo a existência da categoria do JOB.
--
if not exists(
  select name from msdb.dbo.syscategories
   where name = N'[Uncategorized (Local)]' and category_class = 1)
begin
  exec @status = msdb.dbo.sp_add_category
      @class=N'JOB'
    , @type=N'LOCAL'
    , @name=N'[Uncategorized (Local)]'
  if (@@error <> 0 or @status <> 0) goto sair_com_rollback
end

--
-- Cadastrando o JOB.
--
exec @status = msdb.dbo.sp_add_job
    @job_name=N'Processa - Motor de JOBs do Director'
  , @enabled=1
  , @notify_level_eventlog=0
  , @notify_level_email=0
  , @notify_level_netsend=0
  , @notify_level_page=0
  , @delete_level=0
  , @description=N'Tarefa de execução dos scripts de JOB do Director. Scripts de JOB têm o nome `jobtask_*`, independente do esquema.'
  , @category_name=N'[Uncategorized (Local)]'
  , @owner_login_name=N'sa'
  , @job_id=@job_id output
if (@@error <> 0 or @status <> 0) goto sair_com_rollback

--
-- Cadastrando a tarefa a ser executada pelo JOB
--
EXEC @status = msdb.dbo.sp_add_jobstep
    @job_id=@job_id
  , @step_name=N'Execução dos JOBs (host.do_run_all_jobs)' 
  , @step_id=1
  , @cmdexec_success_code=0
  , @on_success_action=1
  , @on_success_step_id=0
  , @on_fail_action=2
  , @on_fail_step_id=0
  , @retry_attempts=0
  , @retry_interval=0
  , @os_run_priority=0
  , @subsystem=N'TSQL'
  , @command=N'exec [host].[do_run_all_jobs] @instance=''9768B94B-BDCC-4B74-81EF-791BF7179EF8'''
  , @database_name=N'DBdirector'
  , @flags=0
if (@@error <> 0 or @status <> 0) goto sair_com_rollback

--
-- Ativando a tarefa do JOB
--
exec @status = msdb.dbo.sp_update_job
    @job_id=@job_id
  , @start_step_id=1
if (@@error <> 0 or @status <> 0) goto sair_com_rollback

--
-- Agendando o JOB para rodar:
--  - Diariamente (@freq_type=4)
--  - A cada 10 (@freq_subday_interval=10) segundos (@freq_subday_type=2)
--
EXEC @status = msdb.dbo.sp_add_jobschedule @job_id=@job_id, @name=N'Agendamento dos JOBs', 
    @enabled=1, 
    @freq_type=4, 
    @freq_interval=1, 
    @freq_subday_type=2, 
    @freq_subday_interval=10, 
    @freq_relative_interval=0, 
    @freq_recurrence_factor=0, 
    @active_start_date=20201115, 
    @active_end_date=99991231, 
    @active_start_time=0, 
    @active_end_time=235959, 
    @schedule_uid=N'f4e4531f-8d1d-4463-a71d-26911ce72972'
if (@@error <> 0 or @status <> 0) goto sair_com_rollback

--
-- Associando o JOB com a máquina de execução de JOBs do servidor corrente.
--
exec @status = msdb.dbo.sp_add_jobserver @job_id = @job_id, @server_name = N'(local)'
if (@@error <> 0 or @status <> 0) goto sair_com_rollback

commit transaction tx

--
-- Saindo
--
goto sair
sair_com_rollback:
  if (@@trancount > 0) rollback transaction tx
sair:
