#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
 
WSRESTFUL clientes DESCRIPTION "Exemplo de serviço REST"
 
WSDATA count      AS INTEGER
WSDATA startIndex AS INTEGER
 
WSMETHOD GET DESCRIPTION "Exemplo de retorno de entidade(s)" WSSYNTAX "/clientes || /clientes/{id}"
WSMETHOD POST DESCRIPTION "Exemplo de inclusao de entidade" WSSYNTAX "/clientes/{id}"
WSMETHOD PUT DESCRIPTION "Exemplo de alteração de entidade" WSSYNTAX "/clientes/{id}"
WSMETHOD DELETE DESCRIPTION "Exemplo de exclusão de entidade" WSSYNTAX "/clientes/{id}"
 
END WSRESTFUL
 
// O metodo GET nao precisa necessariamente receber parametros de querystring, por exemplo:
// WSMETHOD GET WSSERVICE clientes 

WSMETHOD GET WSRECEIVE startIndex, count WSSERVICE clientes
Local i
Local cRet:=""

// define o tipo de retorno do método
::SetContentType("application/json")
 
DEFAULT ::startIndex := 1, ::count := 5

::SetResponse('[')
i:=::startIndex
If Len(::aURLParms) > 0
	SX3->(DbSetOrder(1))
	SA1->(DbSetOrder(1))
	If SA1->(DbSeek(xFilial('SA1')+::aURLParms[1]))
		::SetResponse('{') 
		SX3->(DbGoTop())
		SX3->(DbSeek('SA1'))
		While SX3->(!EOF()) .And. SX3->X3_ARQUIVO=="SA1"
			conout('CAMPO>1>'+SX3->X3_CAMPO+" - "+SA1->A1_COD)
			IF SX3->X3_CONTEXT<>"V"
				if(::startIndex==i,"",::SetResponse(','))
				If valtype(SA1->&(SX3->X3_CAMPO))=="N"
					::SetResponse('"'+SX3->X3_CAMPO+'":"' + Alltrim(Str(SA1->&(SX3->X3_CAMPO))) + '"')
				ElseIf valtype(SA1->&(SX3->X3_CAMPO))=="D"
					::SetResponse('"'+SX3->X3_CAMPO+'":"' + Alltrim(DTOC(SA1->&(SX3->X3_CAMPO))) + '"')
				Else
					::SetResponse('"'+SX3->X3_CAMPO+'":"' + SA1->&(SX3->X3_CAMPO) + '"')
				EndIf
			EndIF
			i++
			SX3->(DbSkip())
		EndDo
		::SetResponse('}')	
 	Else
		::SetResponse('{"id":"invalido"}')
	EndIf
Else
	SA1->(DbSetOrder(1))
	SA1->(DbGoTop())
	While SA1->(!EOF())
		conout('PRODUTO>> '+SA1->(A1_COD+' - '+A1_NOME))
		//cRet+=if(empty(cRet),"",",")
		if(::startIndex==i,"",::SetResponse(','))
		//cRet+="{cod:'"+SA1->A1_COD+"',loja:'"+SA1->A1_LOJA+"',nome:'"+SA1->A1_NOME+"',nmreduz:'"+SA1->A1_NREDUZ+"',id:'"+alltrim(str(SA1->(RECNO())))+"'}"
		::SetResponse('{"cod":"'+SA1->A1_COD+'","loja":"'+SA1->A1_LOJA+'","nome":"'+SA1->A1_NOME+'","nmreduz":"'+SA1->A1_NREDUZ+'","id":"'+alltrim(str(SA1->(RECNO())))+'"}')
		i++
		SA1->(DbSkip())
	EndDo

   
EndIf
::SetResponse(']')
Return .T.
 
// O metodo POST pode receber parametros por querystring, por exemplo:
// WSMETHOD POST WSRECEIVE startIndex, count WSSERVICE clientes
WSMETHOD POST WSSERVICE clientes
Local lPost := .T.
Local cJson
Local oJson	

// Exemplo de retorno de erro
If Len(::aURLParms) == 0
 SetRestFault(400, "id parameter is mandatory")
 lPost := .F.
Else
 // recupera o body da requisição
cJson := ::GetContent()
conout('cBody>> '+cJson)
fwjsondeseialize(cJson,@oJson)

If Len(oJson) > 0
	SX3->(DbSetOrder(1))
	SX3->(DbGoTop())
	SX3->(DbSeek('SA1'))
	While SX3->(!EOF()) .And. SX3->X3_ARQUIVO=="SA1"
		If !(EMPTY(SX3->X3_OBRIGAT))
	    	//If (oJson[Len(oJson)]:&(SX3->X3_CAMPO)== Nil) .Or. Empty(oJson[Len(oJson)]:&(SX3->X3_CAMPO))
	    	//	SetRestFault(400, "id " + SX3->X3_CAMPO + " is mandatory")
	    	//EndIf
	    EndIf 
    SX3->(DbSkip())
    EndDo
    printJson(jsonfields, "| ")
Else
	ConOut("##### [JSON][ERR] " + "Parser 1 com erro" + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
   	ConOut("Erro a partir: " + SubStr(strJson, (nRetParser+1)))
EndIf

 // insira aqui o código para operação inserção
 // exemplo de retorno de um objeto JSON
 ::SetResponse('{"id":' + ::aURLParms[1] + ', "name":"clientes"}')
EndIf
Return lPost
 
// O metodo PUT pode receber parametros por querystring, por exemplo:
// WSMETHOD PUT WSRECEIVE startIndex, count WSSERVICE clientes
WSMETHOD PUT WSSERVICE clientes
Local lPut := .T.
 
// Exemplo de retorno de erro
If Len(::aURLParms) == 0
   SetRestFault(400, "id parameter is mandatory")
   lPut := .F.
Else
   // recupera o body da requisição
   cBody := ::GetContent()
   // insira aqui o código para operação de atualização
   // exemplo de retorno de um objeto JSON
   ::SetResponse('{"id":' + ::aURLParms[1] + ', "name":"clientes"}')
EndIf
Return lPut
 
// O metodo DELETE pode receber parametros por querystring, por exemplo:
// WSMETHOD DELETE WSRECEIVE startIndex, count WSSERVICE clientes
WSMETHOD DELETE WSSERVICE clientes
Local lDelete := .T.
 
// Exemplo de retorno de erro
If Len(::aURLParms) == 0
   SetRestFault(400, "id parameter is mandatory")
   lDelete := .F.
 
Else
   // insira aqui o código para operação exclusão
   // exemplo de retorno de um objeto JSON
   ::SetResponse('{"id":' + ::aURLParms[1] + ', "name":"clientes"}')
EndIf
Return lDelete