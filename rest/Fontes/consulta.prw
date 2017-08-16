#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"


WSRESTFUL CONSULTA DESCRIPTION "Servico para consulta ."
†
WSDATA count††††† AS INTEGER
WSDATA startIndex AS INTEGER
//teste†
WSMETHOD GET DESCRIPTION "Consulta status do PEDIDOWEB." WSSYNTAX "/consulta/{Id1}/{Id2}"
†
END WSRESTFUL
†
// O metodo GET nao precisa necessariamente receber parametros de querystring, por exemplo:
// WSMETHOD GET WSSERVICE U_GDCPED†

WSMETHOD GET WSRECEIVE startIndex, count WSSERVICE U_GDCPED
Local i
Local cRet:=""
Local aCampos := {}
Local cQuery := ""
Local _cAlias:= GetNextAlias()
Local aStruct := {}
Local aCodEmp := {}

conout('Chegou >> rest >>>> CONSULTA')
// define o tipo de retorno do mÈtodo
::SetContentType("application/json")
†
// verifica se recebeu parametro pela URL
// exemplo: http://localhost:8080/U_GDCPED/1

DEFAULT ::startIndex := 1, ::count := 5
::SetResponse('{"Retorno":')
i:=::startIndex
If Len(::aURLParms) == 2
	CONOUT('1>>'+::aURLParms[1]) //Id1
	CONOUT('2>>'+::aURLParms[2]) //Id2

  aCodEmp:={"99","01"}
	If Len(aCodEmp)>0 .And. !Empty(aCodEmp[1]) .And. !Empty(aCodEmp[2])
  conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] LIMPA AMBIENTE')
		RpcClearEnv()
    conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] MONTA AMBIENTE')
		RpcSetType(3)
		RpcSetEnv(aCodEmp[1],aCodEmp[2])
	
	
		  cQuery := " SELECT "
			cQuery += " * "
			cQuery += " FROM " + RetSqlName("ZZZ") + " ZZZ "
			cQuery += " WHERE "
			cQuery += " ZZZ_ID1='" + ::aURLParms[1] + "'"
			cQuery += " ZZZ_ID2='" + ::aURLParms[2] + "'"
			
			cQuery := ChangeQuery(cQuery)
			conout(cQuery)
			If(Select(_cAlias) > 0,(_cAlias)->(DbCloseArea()),)
			DbUseArea(.T., "TOPCONN",TCGenQry(,,cQuery),_cAlias,.F.,.F.)
			(_cAlias)->(DbGoTop())
			aStruct := (_cAlias)->(DbStruct())
			if((_cAlias)->(Eof()),::SetResponse('{"erros":"CONSUTAL nao encontrado"}'),)
			While !(_cAlias)->(Eof())
				nItem := 0 
				If(Len(cRet)>0,::SetResponse(','),)
				cRet := ""
				For x := 1 To Len(aStruct)
					If(x>1,cRet+=",",)
					IF aStruct[x][2] == "C"
						cRet += '"' + aStruct[x][1] + '":"' + Alltrim((_cAlias)->&(aStruct[x][1])) + '"'
					ElseIF aStruct[x][2]=="N"
						cRet += '"' + aStruct[x][1] + '":"' + Alltrim(Str((_cAlias)->&(aStruct[x][1])))+'"' 
					Else
						cRet += '"' + aStruct[x][1] + '":"' + Alltrim((_cAlias)->&(aStruct[x][1]))+'"' 
					EndIf
				Next
				::SetResponse('{' + cRet + '}')
			(_cAlias)->(DbSkip())
			EndDo
::SetResponse('}')
Return .T.
