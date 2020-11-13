drop view if exists [host].[vw_jobtask]
go
create view [host].[vw_jobtask]
as
select [procedure]
     , cast(max(cast([valid] as int)) as bit) as [valid]
  from host.vw_jobtask_parameter
 group by [procedure]
go
