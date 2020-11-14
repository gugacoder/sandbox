if object_id('[host].[locking]') is null begin
  create table [host].[locking] (
    [key] varchar(100) not null primary key,
    [date] datetime not null default (current_timestamp),
    [instance] uniqueidentifier not null
  )
end
go
