if object_id('[host].[job_history]') is null begin
  create table [host].[job_history] (
    [id] bigint not null identity(1,1) primary key,
    [job_id] bigint not null
      foreign key references [host].[job] ([id])
           on delete cascade,
    [lock_key] as concat('job-',[job_id]),
    [due_date] datetime not null,
    [instance] uniqueidentifier null,
    [start_date] datetime null,
    [end_date] datetime null,
    --  0 - scheduled
    --  1 - running
    --  2 - succeeded
    -- -1 - failed
    [status] int not null default (0),
    [fault] nvarchar(max) null,
    [stack_trace] nvarchar(max) null
  )
end
go

if not exists (select 1 from sys.indexes where name = 'ix__host_job_history__job_id') begin
  create index ix__host_job_history__job_id
      on [host].[job_history] ([job_id])
end
go

if not exists (select 1 from sys.indexes where name = 'ix__host_job_history__lock_key') begin
  create index ix__host_job_history__lock_key
      on [host].[job_history] ([lock_key])
end
go

if not exists (select 1 from sys.indexes where name = 'ix__host_job_history__due_date') begin
  create index ix__host_job_history__due_date
      on [host].[job_history] ([due_date])
end
go

if not exists (select 1 from sys.indexes where name = 'ix__host_job_history__status') begin
  create index ix__host_job_history__status
      on [host].[job_history] ([status])
end
go
