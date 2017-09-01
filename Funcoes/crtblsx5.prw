#INCLUDE "Protheus.ch"
#INCLUDE "rwmake.ch"

User Function CRTBLSX5(cGrp,cDesc)
  CdGrp(cGrp,cDesc)
Return
/*-------------------------------------------------------------------------------------|
|Cria Dialog para manutencao em tabela do SX5															   |
|-------------------------------------------------------------------------------------*/

Static Function CdGrp(cGrp,cDesc)
Local cTitle	:= ""
PRIVATE nPosCod	:= 0
PRIVATE nPosDes1	:= 0
PRIVATE nPosDes2	:= 0
PRIVATE nPosDes3	:= 0

PRIVATE aHeader := {}
PRIVATE aCols	:= {}
PRIVATE cAlias	:= "SX5"
PRIVATE cNotHead:= "|X5_TABELA|"
PRIVATE nUsado	:= 0
PRIVATE oDlg

//CrHeader()
CrHeader(cAlias,cNotHead)

nPosCod	:= aScan(aHeader,{|x| Trim(x[2]) == "X5_CHAVE" })
nPosDes1:= aScan(aHeader,{|x| Trim(x[2]) == "X5_DESCRI" })
nPosDes2:= aScan(aHeader,{|x| Trim(x[2]) == "X5_DESCSPA" })
nPosDes3:= aScan(aHeader,{|x| Trim(x[2]) == "X5_DESCENG" })

aHeader[nPosCod][4] := 3

DbSelectArea(cAlias)
(cAlias)->(DbSetOrder(1))

If SX5->(DbSeek(xFilial("SX5")+"00"+cGrp))
	cTitle:=ALLTRIM(SX5->X5_DESCRI)
Else
	AjustSX5(cGrp,cDesc)
	MsgInfo("Foi necessario realizar um ajuste na tabela de dados, abra novamente o cadastro.")
	Return
EndIf
aCols := {}
If SX5->(DbSeek(xFilial("SX5")+cGrp))
	aCols := {}
	While !SX5->(EOF()) .And. ALLTRIM(SX5->X5_TABELA) == cGrp 
		aAdd(aCols,Array(Len(aHeader)+1))
		aCols[Len(aCols)][nPosCod]  := Alltrim(SX5->X5_CHAVE)
		aCols[Len(aCols)][nPosDes1] := (SX5->X5_DESCRI)
		aCols[Len(aCols)][nPosDes2] := (SX5->X5_DESCSPA)
		aCols[Len(aCols)][nPosDes3] := (SX5->X5_DESCENG)
		aCols[Len(aCols)][len(aCols[Len(aCols)])] := .F.
		
		SX5->(DbSkip())
	EndDo
EndIf
DEFINE MsDialog oDlg TITLE cTitle From 000,000 To 030,100 Of oMainWnd

	@ 002,002 To 210,395 Multiline Modify Delete Object oMultiLines
	
Activate MsDialog oDlg On Init EnchoiceBar(oDlg,{|| GrpSalv(cGrp,cDesc),oDlg:End()},{|| oDlg:End() }) Centered

Return

/*-------------------------------------------------------------------------------------|
|Cria Header																		   |
|-------------------------------------------------------------------------------------*/

Static Function CrHeader(cAlias,cNotHead,cHead)
Local i := 0
Local aHead := {}

If(cHead == Nil,aAdd(aHead,{""}),aAdd(aHead,Separa(cHead,"|",.T.)))
//PRIVATE nUsado := 0
 
DbSelectArea("SX3")
DbSetOrder(1)

If DbSeek(cAlias)
	While (!SX3->(EOF()) .And. SX3->X3_ARQUIVO == cAlias)  
	
		If ( X3USO(SX3->X3_USADO) .And. cNivel >= SX3->X3_NIVEL .And. (!(Alltrim(SX3->X3_CAMPO) $ cNotHead) .Or. aScan(aHead[1],{|x| Alltrim(x)==Alltrim(SX3->X3_CAMPO)})>0))
			aAdd(aHeader,{ Trim(X3Titulo()), SX3->X3_CAMPO   , SX3->X3_PICTURE  , ;
			SX3->X3_TAMANHO  , SX3->X3_DECIMAL , SX3->X3_VALID    , ;
			SX3->X3_USADO    , SX3->X3_TIPO    , SX3->X3_ARQUIVO  , ;
			SX3->X3_CONTEXT } )
			
			nUsado++
		Endif
		SX3->(DbSkip())
	EndDo
	IIf(nUsado == 0 , nUsado := Len(aHeader),.F.)
	aAdd(aCols,Array(nUsado+1))
	
	For i := 1 To nUsado
		aCols[1][i] := CriaVar(Alltrim(aHeader[i][2]),.T.)
	Next
	aCols[Len(aCols)][nUsado+1] := .F.
	Iif(cAlias == "SZ0",aCols[Len(aCols)][aScan(aHeader,{|x| Trim(x[2]) == "Z0_ITEM" })] := StrZero(1,TamSX3("Z0_ITEM")[1]),"")
	
EndIf
Return 

/*-------------------------------------------------------------------------------------|
|Cria tabela no SX5 quando nao existe														   |
|-------------------------------------------------------------------------------------*/

Static Function AjustSX5(cGrp,cDesc)

RecLock("SX5",.T.)
	SX5->X5_FILIAL	:= xFilial("SX5")
	SX5->X5_TABELA	:= "00"
	SX5->X5_CHAVE		:= cGrp
	SX5->X5_DESCRI	:= cDesc 
	SX5->X5_DESCSPA 	:= cDesc
	SX5->X5_DESCENG 	:= cDesc
MsUnLock()
Return
