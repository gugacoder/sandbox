-- Script de mapeanto de objetos do DBDIRECTOR
--
-- Cada execução da procedure `api.mapear_objeto_do_director` constrói uma
-- view no DBMERCADOLOGIC apontando para o objeto no DBDIRECTOR.
--

exec api.mapear_objeto_do_director 'TBempresa'
exec api.mapear_objeto_do_director 'TBempresa_atacado_varejo'
exec api.mapear_objeto_do_director 'TBhistorico_estoque'
exec api.mapear_objeto_do_director 'TBitem_estoque'
exec api.mapear_objeto_do_director 'TBitem_estoque_atacado_varejo'
exec api.mapear_objeto_do_director 'TBitem_estoque_origem'
exec api.mapear_objeto_do_director 'TBmotivo_movto_endereco'
exec api.mapear_objeto_do_director 'TBopcoes'
exec api.mapear_objeto_do_director 'TBparte_item_composto'
exec api.mapear_objeto_do_director 'TBunidade_item_estoque'
exec api.mapear_objeto_do_director 'TBusuario'
exec api.mapear_objeto_do_director 'TBvenda_diaria'
exec api.mapear_objeto_do_director 'VWPRECO1'

