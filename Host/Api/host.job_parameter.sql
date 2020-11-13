if object_id('[host].[job_parameter]') is null begin
  create table [host].[job_parameter] (
    [id] bigint not null identity(1, 1) primary key,
    [job_id] bigint not null
      foreign key references [host].[job] ([id])
           on delete cascade,
    [name] varchar(100) not null,
    [value] sql_variant null
  )

  create index ix__host_job_parameter__job_id__name
      on [host].[job_parameter] ([job_id], [name])
end
go
