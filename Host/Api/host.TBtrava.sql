--
-- TABLE host.TBtrava
--
if object_id('host.TBtrava') is null begin
  create table host.TBtrava (
    DFchave_travada varchar(100) not null primary key,
    DFdata_travamento datetime not null default (current_timestamp),
    DFguid_instancia uniqueidentifier not null
  )
end
go
