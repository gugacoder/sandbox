if not exists (select 1 from sys.schemas where name = 'scriptpack')
  exec('create schema scriptpack')
go
