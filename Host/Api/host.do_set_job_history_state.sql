drop procedure if exists [host].[do_set_job_history_state]
go
create procedure [host].[do_set_job_history_state]
  @job_history_id int,
  @end_date datetime,
  @fault nvarchar(max) null,
  @stack_trace nvarchar(max) null
as
begin
  set nocount on

  declare @message nvarchar(max)
  declare @severity int
  declare @state int

  if @fault is not null and @end_date is null
    set @end_date = current_timestamp

  begin try
    begin transaction tx

    update [host].[job_history]
       set [end_date] = @end_date
         , [fault] = @fault
         , [stack_trace] = @stack_trace
     where [id] = @job_history_id

    commit transaction tx
  end try
  begin catch
    if @@trancount > 0
      rollback transaction tx
      
    set @message = concat(error_message(),' (linha ',error_line(),')')
    set @severity = error_severity()
    set @state = error_state()
    raiserror (@message, @severity, @state) with nowait
  end catch
end
go
