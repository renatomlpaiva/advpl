#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

User Function AltColor()
Local cQuery   := ""
Local aColumn := {}
Local aStruct  := {}
Local _cAlias := "SA1"
Local _cAlias1 := GetNextAlias()
Local oBrw
Local aItens := {}
Local oBrowse 



If SX2->(DbSeek(_cAlias))
	cQuery := " SELECT * FROM " + RetSqlName(_cAlias) + " " + _cAlias
	
	If Select(_cAlias1) > 0
		(_cAlias1)->(DbCloseArea())
	EndIf
	
	cQuery := ChangeQuery(cQuery)
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), _cAlias1, .F., .F.)
	(_cAlias1)->(DBGOTOP())
	aStruct := (_cAlias1)->(DbStruct())
	
	SX3->(DbSetOrder(1))
	If SX3->(DbSeek(_cAlias))
		
		
		//aAdd(aColumn,{'',&("{|| (_cAlias1)->"+_cAlias+'_MARK}'),"C","","CENTER",4,0,,,,,,,,,}) //MarkColumn
		
		While !SX3->(Eof()) .And. SX3->X3_ARQUIVO == _cAlias
		
			If X3Uso(SX3->X3_USADO) .And. cNivel >= SX3->X3_NIVEL .And. aScan(aStruct,{|x| Alltrim(x[1])== Alltrim(SX3->X3_CAMPO)})>0 
					
				aAdd(aColumn,{X3Titulo(),;							//01
								&("{|| "+SX3->X3_CAMPO+"}"),;//IF(SX3->X3_TIPO=="D",&("{|| STOD("+SX3->X3_CAMPO+")}"),&("{|| "+SX3->X3_CAMPO+"}")),;//02
								SX3->X3_TIPO,;						//03
								"",;						//04
								If(SX3->X3_TIPO=="N","RIGHT","LEFT"),;										//05
								SX3->X3_TAMANHO,;						//06
								SX3->X3_DECIMAL;
								})										
			EndIf
		SX3->(DbSkip())
		EndDo
	EndIf
	
	oDlg := MSDialog():New(000,000,550,700,SX2->X2_NOME,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
	
	oBrw := FWBrowse():New()
	
	oBrw:SetOwner(oDlg)
	oBrw:SetDataTable() 
	oBrw:SetAlias(_cAlias)
	oBrw:SetDescription(SX2->X2_NOME)
	
	aEval(aColumn,{|x| oBrw:AddColumn(x)})
	
	oBrw:Activate()
	
	oBrowse := oBrw:Browse()
	
	oBrowse:SetColumnColor(0,CLR_YELLOW,0)
   	oBrowse:SetColumnColor(1,CLR_YELLOW,0)
   	oBrowse:SetColumnColor(2,CLR_BLUE,CLR_WHITE)
	
	aButtons := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,"Salvar"},{.T.,"Cancelar"},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil},{.T.,Nil}}
	aBut := {}
	aAdd(aBut,{"View", {||  FWExecView('Inclusao por FWExecView','ALTCOR2', MODEL_OPERATION_VIEW, , { || .T. }, , ,aButtons )}, "View...", "View" , {|| .T.}})
	oDlg:bInit := {|| EnchoiceBar(oDlg,{|| oDlg:End()}, {||oDlg:End()},,@aBut)}
	oDlg:lCentered := .T.
	oDlg:lMaximized := .T.
	oDlg:Activate()
EndIf

Return(.t.)



