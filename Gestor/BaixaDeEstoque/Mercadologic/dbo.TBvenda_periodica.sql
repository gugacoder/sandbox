if object_id('dbo.TBvenda_periodica') is null begin
	create table dbo.TBvenda_periodica (
		DFid_venda_diaria bigint identity(1,1) not null,
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

	create index IX__TBvenda_periodica__DFid_unidade_item_estoque
	    on dbo.TBvenda_periodica (DFid_unidade_item_estoque)

	create index IX__TBvenda_periodica__DFcod_empresa
	    on dbo.TBvenda_periodica (DFcod_empresa)

	create index IX__TBvenda_periodica__DFdata_venda
	    on dbo.TBvenda_periodica (DFdata_venda)

	create index IX__TBvenda_periodica__DFestoque_atualizado
	    on dbo.TBvenda_periodica (DFestoque_atualizado)
end
