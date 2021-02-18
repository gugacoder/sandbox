-- drop table dbo.TBvenda_periodica_auditoria
if object_id('dbo.TBvenda_periodica_auditoria') is null begin
  create table dbo.TBvenda_periodica_auditoria (
    DFid_venda_periodica_auditoria bigint not null primary key identity(1,1),
    DFcod_empresa int not null,
    DFdata_execucao datetime not null,
    DFid_usuario int not null,
    DFid_formulario int null
  )
  
  create index IX__TBvenda_periodica_auditoria__DFcod_empresa__DFdata_execucao
      on dbo.TBvenda_periodica_auditoria (DFcod_empresa, DFdata_execucao desc)
end
