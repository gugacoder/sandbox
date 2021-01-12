-- View: public.vw_item_cupom_fiscal

-- DROP VIEW public.vw_item_cupom_fiscal;

CREATE OR REPLACE VIEW public.vw_item_cupom_fiscal AS
 SELECT

    pdv.identificador AS id_caixa,

    itemcupomfiscal.iditem AS id_item,
    itemcupomfiscal.indice AS indice_no_cupom,
    
    cupomfiscal.coo AS numero_cupom,
    caixa.datamovimento AS data_movimento,
    
    itemcupomfiscal.quantidade AS dfquantidade_venda_bruta,
    itemcupomfiscal.totalbruto AS dfvalor_venda_bruta,
    CASE
        WHEN ecf.tipo::text = 'NFCE'::text THEN round(itemcupomfiscal.precocusto * itemcupomfiscal.quantidade, 2)
        ELSE trunc(itemcupomfiscal.precocusto * itemcupomfiscal.quantidade, 2)
    END AS dfvalor_custo_bruto,

    itemcupomfiscal.totaldesconto AS dfvalor_desconto,
    CASE
        WHEN ecf.tipo::text = 'NFCE'::text THEN round(itemcupomfiscal.acrescimo * itemcupomfiscal.quantidade, 2)
        ELSE trunc(itemcupomfiscal.acrescimo * itemcupomfiscal.quantidade, 2)
    END AS dfvalor_acrescimo,

    aliquota.idaliquotaorigem AS dfaliquota_origem,
    itemcupomfiscal.preco AS dfpreco_item,
    aliquota.percentual AS dfpercentual_aliquota

   FROM itemcupomfiscal
     JOIN aliquota ON itemcupomfiscal.tributacao::text = aliquota.id::text
     JOIN cupomfiscal ON cupomfiscal.id = itemcupomfiscal.idcupomfiscal
     JOIN sessao ON sessao.id = cupomfiscal.idsessao
     JOIN caixa ON sessao.idcaixa = caixa.id
     JOIN pdv ON caixa.idpdv = pdv.id
     JOIN ecf ON ecf.id = pdv.idecf;

ALTER TABLE public.vw_item_cupom_fiscal
    OWNER TO postgres;
