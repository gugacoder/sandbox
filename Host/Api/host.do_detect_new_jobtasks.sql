drop procedure if exists [host].[do_detect_new_jobtasks]
go
create procedure [host].[do_detect_new_jobtasks]
  @instance uniqueidentifier,
  @extra_args [host].[tp_parameter] readonly
as
begin
  set nocount on

  declare @message nvarchar(max)
  declare @procedure varchar(100)
  declare @tb_procedure table (
    [procedure] varchar(100)
  )

  insert into @tb_procedure ([procedure])
  select [procedure]
    from [host].[vw_jobtask]
   where [valid] = 1
     and not exists (
          select 1 from [host].[job]
           where [procedure] = [host].[vw_jobtask].[procedure]
     )

  select @procedure = min([procedure]) from @tb_procedure
  while @procedure is not null begin

    begin try

      exec [host].[do_run_jobtask]
        @procedure=@procedure,
        @command='init',
        @instance=@instance,
        @args=@extra_args

    end try begin catch
      set @message = concat(error_message(),' (linha ',error_line(),')')
      raiserror ('Falha inicializando JOB. (procedure = %s) - Causa: %s',10,1,@procedure,@message) with nowait
    end catch
      
    select @procedure = min([procedure]) from @tb_procedure where [procedure] > @procedure
  end
end
