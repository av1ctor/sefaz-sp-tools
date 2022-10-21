function errorHandler(err)
	onError(err)
	onError(debug.traceback())
end

----------------------------------------------------------------------
-- resumo por CFOP na LRE
function LRE_cfop(db, ws, opcoes)

	ds = db_exec( db, [[
		select
			an.cfop, 
			(select descricao from conf.cfop c where c.cfop = an.cfop) descricao, 
			(select operacao from conf.cfop c where c.cfop = an.cfop) operacao,
			sum(an.valorOp) vlOper, 
			sum(an.bc) bcIcms, 
			sum(an.icms) vlIcms,
			((1.0 - iif(sum(an.valorOp) > 0.0, sum(an.bc) / sum(an.valorOp), 1.0))) redBcIcms,
			iif(sum(an.valorOp) > 0, sum(an.icms) / sum(an.valorOp), 0.0) aliqIcms,
			sum(an.bcIcmsST) bcIcmsST, 
			sum(an.icmsST) vlIcmsST,
			iif(sum(an.valorOp) > 0.0, sum(an.icmsST) / sum(an.valorOp), 0.0) aliqIcmsST,
			sum(an.ipi) vlIpi
			from EFD_Anal an
			where 
				an.operacao = 0
			group by an.cfop
			order by vlOper desc
	]])
	
	while ds_hasNext( ds ) do
		efd_plan_resumos_AddRow( ws, ds, opcoes, TR_CFOP, TL_ENTRADAS )
		ds_next( ds )
	end
	
	ds_del( ds )
end

function LRE_criarResumoCFOP(db, ws, opcoes)

	xpcall(LRE_cfop, errorHandler, db, ws, opcoes)
	
end

----------------------------------------------------------------------
-- resumo por CST na LRE
function LRE_cst(db, ws, opcoes)

	ds = db_exec( db, [[
		select
			an.cst, 
			(select origem from conf.cst c where c.cst = an.cst) origem, 
			(select tributacao from conf.cst c where c.cst = an.cst) tributacao, 
			sum(an.valorOp) vlOper, 
			sum(an.bc) bcIcms, 
			sum(an.icms) vlIcms,
			((1.0 - iif(sum(an.valorOp) > 0.0, sum(an.bc) / sum(an.valorOp), 1.0))) redBcIcms,
			iif(sum(an.valorOp) > 0, sum(an.icms) / sum(an.valorOp), 0.0) aliqIcms,
			sum(an.bcIcmsST) bcIcmsST, 
			sum(an.icmsST) vlIcmsST,
			iif(sum(an.valorOp) > 0.0, sum(an.icmsST) / sum(an.valorOp), 0.0) aliqIcmsST,
			sum(an.ipi) vlIpi
			from EFD_Anal an
			where 
				an.operacao = 0
			group by an.cst
			order by vlOper desc
	]])
	
	while ds_hasNext( ds ) do
		efd_plan_resumos_AddRow( ws, ds, opcoes, TR_CST, TL_ENTRADAS )
		ds_next( ds )
	end
	
	ds_del( ds )
end

function LRE_criarResumoCST(db, ws, opcoes)

	xpcall(LRE_cst, errorHandler, db, ws, opcoes)
	
end
----------------------------------------------------------------------
-- resumo por CST e CFOP na LRE
function LRE_cstCfop(db, ws, opcoes)

	ds = db_exec( db, [[
		select
			an.cst,
			(select origem from conf.cst c where c.cst = an.cst) origem, 
			(select tributacao from conf.cst c where c.cst = an.cst) tributacao, 
			an.cfop,
			(select descricao from conf.cfop c where c.cfop = an.cfop) descricao, 
			(select operacao from conf.cfop c where c.cfop = an.cfop) operacao,
			sum(an.valorOp) vlOper, 
			sum(an.bc) bcIcms, 
			sum(an.icms) vlIcms,
			((1.0 - iif(sum(an.valorOp) > 0.0, sum(an.bc) / sum(an.valorOp), 1.0))) redBcIcms,
			iif(sum(an.valorOp) > 0, sum(an.icms) / sum(an.valorOp), 0.0) aliqIcms,
			sum(an.bcIcmsST) bcIcmsST, 
			sum(an.icmsST) vlIcmsST,
			iif(sum(an.valorOp) > 0.0, sum(an.icmsST) / sum(an.valorOp), 0.0) aliqIcmsST,
			sum(an.ipi) vlIpi
			from EFD_Anal an
			where 
				an.operacao = 0
			group by an.cst, an.cfop
			order by vlOper desc
	]])
	
	while ds_hasNext( ds ) do
		efd_plan_resumos_AddRow( ws, ds, opcoes, TR_CST_CFOP, TL_ENTRADAS )
		ds_next( ds )
	end
	
	ds_del( ds )
end

function LRE_criarResumoCstCfop(db, ws, opcoes)

	xpcall(LRE_cstCfop, errorHandler, db, ws, opcoes)
	
end

----------------------------------------------------------------------
-- resumo por CFOP na LRS
function LRS_cfop(db, ws, opcoes)

	ds = db_exec( db, [[
		select
			an.cfop, 
			(select descricao from conf.cfop c where c.cfop = an.cfop) descricao, 
			(select operacao from conf.cfop c where c.cfop = an.cfop) operacao,
			sum(an.valorOp) vlOper, 
			sum(an.bc) bcIcms, 
			sum(an.icms) vlIcms,
			((1.0 - iif(sum(an.valorOp) > 0.0, sum(an.bc) / sum(an.valorOp), 1.0))) redBcIcms,
			iif(sum(an.valorOp) > 0, sum(an.icms) / sum(an.valorOp), 0.0) aliqIcms,
			sum(an.bcIcmsST) bcIcmsST, 
			sum(an.icmsST) vlIcmsST,
			iif(sum(an.valorOp) > 0.0, sum(an.icmsST) / sum(an.valorOp), 0.0) aliqIcmsST,
			sum(an.ipi) vlIpi
			from EFD_Anal an
			where 
				an.operacao = 1
			group by an.cfop
			order by vlOper desc
	]])
	
	while ds_hasNext( ds ) do
		efd_plan_resumos_AddRow( ws, ds, opcoes, TR_CFOP, TL_SAIDAS )
		ds_next( ds )
	end
	
	ds_del( ds )
end

function LRS_criarResumoCFOP(db, ws, opcoes)

	xpcall(LRS_cfop, errorHandler, db, ws, opcoes)
end

----------------------------------------------------------------------
-- resumo por CST na LRS
function LRS_cst(db, ws, opcoes)

	ds = db_exec( db, [[
		select
			an.cst, 
			(select origem from conf.cst c where c.cst = an.cst) origem, 
			(select tributacao from conf.cst c where c.cst = an.cst) tributacao, 
			sum(an.valorOp) vlOper, 
			sum(an.bc) bcIcms, 
			sum(an.icms) vlIcms,
			((1.0 - iif(sum(an.valorOp) > 0.0, sum(an.bc) / sum(an.valorOp), 1.0))) redBcIcms,
			iif(sum(an.valorOp) > 0, sum(an.icms) / sum(an.valorOp), 0.0) aliqIcms,
			sum(an.bcIcmsST) bcIcmsST, 
			sum(an.icmsST) vlIcmsST,
			iif(sum(an.valorOp) > 0.0, sum(an.icmsST) / sum(an.valorOp), 0.0) aliqIcmsST,
			sum(an.ipi) vlIpi
			from EFD_Anal an
			where 
				an.operacao = 1
			group by an.cst
			order by vlOper desc
	]])
	
	while ds_hasNext( ds ) do
		efd_plan_resumos_AddRow( ws, ds, opcoes, TR_CST, TL_SAIDAS )
		ds_next( ds )
	end
	
	ds_del( ds )
end

function LRS_criarResumoCST(db, ws, opcoes)

	xpcall(LRS_cst, errorHandler, db, ws, opcoes)
	
end

----------------------------------------------------------------------
-- resumo por CST e CFOP na LRS
function LRS_cstCfop(db, ws, opcoes)

	ds = db_exec( db, [[
		select
			an.cst, 
			(select origem from conf.cst c where c.cst = an.cst) origem, 
			(select tributacao from conf.cst c where c.cst = an.cst) tributacao, 
			an.cfop, 
			(select descricao from conf.cfop c where c.cfop = an.cfop) descricao, 
			(select operacao from conf.cfop c where c.cfop = an.cfop) operacao,
			sum(an.valorOp) vlOper, 
			sum(an.bc) bcIcms, 
			sum(an.icms) vlIcms,
			((1.0 - iif(sum(an.valorOp) > 0.0, sum(an.bc) / sum(an.valorOp), 1.0))) redBcIcms,
			iif(sum(an.valorOp) > 0, sum(an.icms) / sum(an.valorOp), 0.0) aliqIcms,
			sum(an.bcIcmsST) bcIcmsST, 
			sum(an.icmsST) vlIcmsST,
			iif(sum(an.valorOp) > 0.0, sum(an.icmsST) / sum(an.valorOp), 0.0) aliqIcmsST,
			sum(an.ipi) vlIpi
			from EFD_Anal an
			where 
				an.operacao = 1
			group by an.cst, an.cfop
			order by vlOper desc
	]])
	
	while ds_hasNext( ds ) do
		efd_plan_resumos_AddRow( ws, ds, opcoes, TR_CST_CFOP, TL_SAIDAS )
		ds_next( ds )
	end
	
	ds_del( ds )
end

function LRS_criarResumoCstCfop(db, ws, opcoes)

	xpcall(LRS_cstCfop, errorHandler, db, ws, opcoes)
	
end
