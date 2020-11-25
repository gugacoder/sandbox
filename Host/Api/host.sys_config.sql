if object_id('[host].[sys_config]') is null begin
  create table [host].[sys_config] (
    [key] varchar(400) not null primary key nonclustered,
    [value] sql_variant null
  )
end
go



