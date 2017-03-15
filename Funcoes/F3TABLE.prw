#Include 'Protheus.ch'
#Include 'FWBrowse.ch'

Static __cF3Ret
User Function F3TABLE(_cAli,_cField,cRet)
Local cQuery   := ""
Local aColumn := {}
Local aStruct  := {}
Local cReadVar

Private _cAlias := _cAli
Private _cFieldRet := _cField
Private _cAlias1 := GetNextAlias()
Private oMark
Private aItens := {}
Private aRet := {}

DEFAULT cRet     := PadR("",TamSX3("ZZW_CANAL")[1])

cReadVar := ReadVar()
cRet := GetMemVar(cReadVar)

If(Empty(cRet),,aRet := Separa(cRet,";",.F.))

If SX2->(DbSeek(_cAlias))
	cQuery := " SELECT '' " + _cAlias + "_MARK,* FROM " + RetSqlName(_cAlias) + " " + _cAlias
	
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
	
	oMark := FWBrowse():New()
	
	oMark:SetOwner(oDlg)
	oMark:SetDataTable() 
	oMark:SetAlias(_cAlias)
	oMark:SetDescription(SX2->X2_NOME)
	//oMark:DisableConfig()
	//oMark:DisableSeek()
	oMark:AddMarkColumns({|| If((nPos:= aScan(aRet,{|x| Alltrim((_cAlias)->&(_cFieldRet))== Alltrim(x)}))>0,'LBOK','LBNO')},{|| If((nPos:= aScan(aRet,{|x| Alltrim((_cAlias)->&(_cFieldRet))== Alltrim(x)}))==0,aAdd(aRet,(_cAlias)->&(_cFieldRet)),eVal({|| aDel(aRet,nPos),aSize(aRet,Len(aRet)-1)})) },{|| })
	aEval(aColumn,{|x| oMark:AddColumn(x)})
	
	oMark:Activate()
	//aButtons := {}
	
	oDlg:bInit := {|| EnchoiceBar(oDlg, {|| cRet := "", aEval(aRet,{|x| If(Empty(x),,cRet += Alltrim(x)+";")}),oDlg:End()}, {||oDlg:End()},,)}
	oDlg:lCentered := .T.
	oDlg:Activate()
EndIf
__cF3Ret := cRet

SetMemVar(cReadVar,cRet)
SysRefresh(.T.)

Return(.t.)

/*StaticCall(F3TABLE,GetF3Table)*/
Static Function GETF3Table()
Return(__cF3Ret)

Static Function MenuDef()
Local aRotina := {}
Return aRotina // FWMVCMenu('F3TABLE')


