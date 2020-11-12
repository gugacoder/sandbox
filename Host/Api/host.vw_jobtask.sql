--
-- VIEW host.vw_jobtask
--
drop view if exists host.vw_jobtask
go
create view host.vw_jobtask
as
select DFesquema
     , DFmodulo
     , DFtarefa
     , DFprocedure
     , cast(max(cast(DFvalido as int)) as bit) as DFvalido
     , cast(max(case DFparametro when '@automatico' then 1 else 0 end) as bit) as DFautomatico
     , cast(max(case DFparametro when '@cod_empresa' then 1 else 0 end) as bit) as DFpor_empresa
  from host.vw_jobtask_parametro
 group by DFesquema, DFmodulo, DFtarefa, DFprocedure
go
