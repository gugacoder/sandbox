if object_id('[host].[job_parameter]') is null begin
  create table [host].[job_parameter] (
    [job_id] bigint not null
      foreign key references [host].[job] ([id])
           on delete cascade,
    [name] varchar(100) not null,
    [value] sql_variant null,
    primary key ([job_id], [name])
  )
end
go
