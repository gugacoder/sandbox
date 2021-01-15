if object_id('rascunho.TBvenda_diaria') is null begin
	create table rascunho.TBvenda_diaria (
		DFid_venda_diaria int identity(1,1) not null,
		DFid_unidade_item_estoque int not null,
		DFcod_empresa int not null,
		DFdata_venda smalldatetime not null,
		DFquantidade_vendida decimal(18, 4) not null,
		DFvalor_venda decimal(18, 4) not null,
		DFcusto_venda decimal(18, 4) not null,
		DFvalor_icms decimal(18, 4) not null,
		DFvalor_pis decimal(18, 6) not null,
		DFvalor_cofins decimal(18, 6) not null,
		DFvalor_encargos decimal(18, 6) not null,
		DFestoque_atualizado bit not null,
		DFvalor_desconto decimal(18, 4) not null,
		DFcusto_contabil_venda decimal(18, 4) null
	)
end
