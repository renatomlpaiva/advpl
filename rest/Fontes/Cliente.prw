#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

#DEFINE cCmpObg  "|A1_CGC|A1_PESSOA|A1_NOME|A1_NREDUZ|A1_CEP|A1_EMAIL|A1_NATUREZ|"
#DEFINE aCmpObg {"A1_CGC","A1_PESSOA","A1_NOME","A1_NREDUZ","A1_CEP","A1_EMAIL","A1_NATUREZ"}�

WSRESTFUL clientes DESCRIPTION "Exemplo de servi�o REST"
�
WSDATA count����� AS INTEGER
WSDATA startIndex AS INTEGER
�
WSMETHOD GET DESCRIPTION "Exemplo de retorno de entidade(s)" WSSYNTAX "/clientes || /clientes/{id}"
WSMETHOD POST DESCRIPTION "Exemplo de inclusao de entidade" WSSYNTAX "/clientes/{id}"
WSMETHOD PUT DESCRIPTION "Exemplo de altera��o de entidade" WSSYNTAX "/clientes/{id}"
//WSMETHOD DELETE DESCRIPTION "Exemplo de exclus�o de entidade" WSSYNTAX "/clientes/{id}"
�
END WSRESTFUL
�
// O metodo GET nao precisa necessariamente receber parametros de querystring, por exemplo:
// WSMETHOD GET WSSERVICE clientes�

WSMETHOD GET WSRECEIVE startIndex, count WSSERVICE clientes
Local i
Local cRet:=""

// define o tipo de retorno do m�todo
::SetContentType("application/json")
�
DEFAULT ::startIndex := 1, ::count := 5

::SetResponse('{"Cliente":')
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
				::SetResponse('"'+SX3->X3_CAMPO+'":"' + if(SX3->X3_TIPO=="N",Alltrim(Str(SA1->&(SX3->X3_CAMPO))),;
															  if(SX3->X3_TIPO=="D",DTOC(SA1->&(SX3->X3_CAMPO)),;
															  if(SX3->X3_TIPO=="C",SA1->&(SX3->X3_CAMPO),''))) + '"')
			EndIF
			i++
			SX3->(DbSkip())
		EndDo
		::SetResponse('}')	
�	Else
		::SetResponse('{"id":"invalido"}')
	EndIf
Else
	SA1->(DbSetOrder(1))
	SA1->(DbGoTop())
	While SA1->(!EOF())
		if(::startIndex==i,"",::SetResponse(','))
		::SetResponse('{"cod":"'+SA1->A1_COD+'","loja":"'+SA1->A1_LOJA+'","nome":"'+SA1->A1_NOME+'","nmreduz":"'+SA1->A1_NREDUZ+'","id":"'+alltrim(str(SA1->(RECNO())))+'"}')
		i++
		SA1->(DbSkip())
	EndDo

�� 
EndIf
::SetResponse('}')
Return .T.
�
// O metodo POST pode receber parametros por querystring, por exemplo:
// WSMETHOD POST WSRECEIVE startIndex, count WSSERVICE clientes
WSMETHOD POST WSSERVICE clientes
Local lPost := .T.
Local cJson	:= ""
Local aErro	:={}�
Local aRet		:={}�
Local oJson	
Local oHeader	
Local oContent	
Local oJsonParser
Local jsonfields := {}
Local nRetParser := 0
Local lRetParser := .F.
Local aHeadJson	:= {}
Local aContJson	:= {}
Local cRet := ""
Local cCnpj:= ""
Local _lAuto := .F.

oJsonParser := tJsonParser():New()

conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST_PUT_CLIENTES INICIO')
cCnpj := If(Len(::aURLParms) > 0,::aURLParms[1],"") 
	aCodEmp:=StaticCall(U_MATA410,GetCodEmp,cCnpj)
	If Len(aCodEmp)>0
		RpcClearEnv()
		RpcSetType(3)
		RpcSetEnv(aCodEmp[1],aCodEmp[2])
	
	�� // recupera o body da requisi��o
		cJson := ::GetContent()
		conout('body>>'+cJson)
		fwjsondeseialize(cJson,@oJson)
		lRetParser := oJsonParser:Json_Parser(cJson,Len(cJson),@jsonfields,@nRetParser)
				
		aContJson := jsonfields[1][2][2][2]
		
		If Len(aContJson) > 0 .And. lRetParser
			conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST_PUT_CLIENTES JSON RECEBIDO OK')
			aRet := InsereCli(oJson,aContJson)
			If Len(aRet[2]) > 0 .AND. !aRet[1]
				aErro:= aRet[2]
				::SetResponse('{ "Cliente": {')
				If Len(aRet[5])>0
					For j:=1 To Len(aRet[5])
						::SetResponse(if(j==1,'',','))
						::SetResponse('"'+aRet[5][j][1]+'":"' + if(Valtype(aRet[5][j][2])=="C",aRet[5][j][2],;
																	  if(Valtype(aRet[5][j][2])=="D",DToS(aRet[5][j][2]),;
																	  if(Valtype(aRet[5][j][2])=="N",Alltrim(str(aRet[5][j][2])),aRet[5][j][2]))) + '"')
					Next
				Else
					For j:=1 To Len(aContJson)
						::SetResponse(if(j==1,'',','))
						::SetResponse('"'+aContJson[j][1]+'":"' + aContJson[j][2]+ '"')
					Next
				EndIf 
				::SetResponse('},"errors": [')
				conout('print ERRO >>'+STR(LEN(aErro)))
				For i:=1 To Len(aErro)
				conout('print ERRO >'+str(i)+'>'+STR(LEN(aErro)))
					If ALLTRIM(aErro[i][1])=="ExecAuto"
						_lAuto := .T.
						cRet += if(i==1,'{"field":"'+aErro[i][1]+'","description":"','')
						cRet += '|' + StrZero(i,2) + ' | ' + StrTran(aErro[i][2],CRLF,"") 
					Else
						cRet += if(i==1,'',',')
						cRet += '{"field":"'+aErro[i][1]+'","description":"'+aErro[i][2]+'"}'
					EndIf
				Next
				cRet += if(_lAuto,'"}','')
				::SetResponse( cRet)
				HTTPSetStatus(400)
				::SetResponse(']}')
				//lPost := .F.
			Else
				::SetResponse('{ "Cliente": {')
				For j:=1 To Len(aRet[5])
					::SetResponse(if(j==1,'',','))
					::SetResponse('"'+aRet[5][j][1]+'":"' + if(Valtype(aRet[5][j][2])=="C",aRet[5][j][2],;
																  if(Valtype(aRet[5][j][2])=="D",DToS(aRet[5][j][2]),;
																  if(Valtype(aRet[5][j][2])=="N",Alltrim(str(aRet[5][j][2])),aRet[5][j][2]))) + '"')
				Next 
				::SetResponse('},"errors": null')
				::SetResponse('}')
			EndIf
		
		Else
		�� SetRestFault(400, "body parameter error")
	�� 		lPost := .F.
	
			ConOut("##### [JSON][ERR] " + "Parser 1 com erro" + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
		   	ConOut("Erro a partir: " + SubStr(strJson, (nRetParser+1)))
		EndIf
	Else
		//SetRestFault(400, "Erro n�o encontrado empresa para processamento")
		HTTPSetStatus(404,"Erro n�o encontrado empresa para processamento")
		lPost := .F.
	EndIf
/*Else
	conout('ERRO')
	//HTTPSetStatus(422,"ERRO")
	SetRestFault(416, "parametro obrigatorio")
	lPut := .F.
EndIf*/
conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST_PUT_CLIENTES FIM')

Return lPost
�
// O metodo PUT pode receber parametros por querystring, por exemplo:
// WSMETHOD PUT WSRECEIVE startIndex, count WSSERVICE clientes
WSMETHOD PUT WSSERVICE clientes
Local lPut 	:= .T.
Local cJson	:= ""
Local aErro	:={}�
Local aRet		:={}�
Local oJson	
Local oHeader	
Local oContent	
Local oJsonParser
Local jsonfields := {}
Local nRetParser := 0
Local lRetParser := .F.
Local aHeadJson	:= {}
Local aContJson	:= {}
Local cRet := ""
Local cCnpj:= ""
Local _lAuto := .F.

oJsonParser := tJsonParser():New()

conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST_PUT_CLIENTES INICIO')
cCnpj := If(Len(::aURLParms) > 0,::aURLParms[1],"") 
	aCodEmp:=StaticCall(U_MATA410,GetCodEmp,cCnpj)
	If Len(aCodEmp)>0
		RpcClearEnv()
		RpcSetType(3)
		RpcSetEnv(aCodEmp[1],aCodEmp[2])
	// Exemplo de retorno de erro
	�� // recupera o body da requisi��o
		cJson := ::GetContent()
		conout('body>>'+cJson)
		fwjsondeseialize(cJson,@oJson)
		lRetParser := oJsonParser:Json_Parser(cJson,Len(cJson),@jsonfields,@nRetParser)
				
		aContJson := jsonfields[1][2][2][2]
		
		If Len(aContJson) > 0 .And. lRetParser
			conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST_PUT_CLIENTES JSON RECEBIDO OK')
			aRet := InsereCli(oJson,aContJson)
			If Len(aRet[2]) > 0 .AND. !aRet[1]
				aErro:= aRet[2]
				::SetResponse('{ "Cliente": {')
				If Len(aRet[5])>0
					For j:=1 To Len(aRet[5])
						::SetResponse(if(j==1,'',','))
						::SetResponse('"'+aRet[5][j][1]+'":"' + if(Valtype(aRet[5][j][2])=="C",aRet[5][j][2],;
																	  if(Valtype(aRet[5][j][2])=="D",DToS(aRet[5][j][2]),;
																	  if(Valtype(aRet[5][j][2])=="N",Alltrim(str(aRet[5][j][2])),aRet[5][j][2]))) + '"')
					Next
				Else
					For j:=1 To Len(aContJson)
						::SetResponse(if(j==1,'',','))
						::SetResponse('"'+aContJson[j][1]+'":"' + aContJson[j][2]+ '"')
					Next
				EndIf 
				::SetResponse('},"errors": [')
				conout('print ERRO >>'+STR(LEN(aErro)))
				For i:=1 To Len(aErro)
				conout('print ERRO >'+str(i)+'>'+STR(LEN(aErro)))
					If ALLTRIM(aErro[i][1])=="ExecAuto"
						_lAuto := .T.
						cRet += if(i==1,'{"field":"'+aErro[i][1]+'","description":"','')
						cRet += '|' + StrZero(i,2) + ' | ' + StrTran(aErro[i][2],CRLF,"") 
					Else
						cRet += if(i==1,'',',')
						cRet += '{"field":"'+aErro[i][1]+'","description":"'+aErro[i][2]+'"}'
					EndIf
				Next
				cRet += if(_lAuto,'"}','')
				::SetResponse( cRet)
				HTTPSetStatus(400)
				::SetResponse(']}')
				//lPut := .F.
			Else
				::SetResponse('{ "cliente": {')
				For j:=1 To Len(aRet[5])
					::SetResponse(if(j==1,'',','))
					::SetResponse('"'+aRet[5][j][1]+'":"' + if(Valtype(aRet[5][j][2])=="C",aRet[5][j][2],;
																  if(Valtype(aRet[5][j][2])=="D",DToS(aRet[5][j][2]),;
																  if(Valtype(aRet[5][j][2])=="N",Alltrim(str(aRet[5][j][2])),aRet[5][j][2]))) + '"')
				Next 
				::SetResponse('},"errors": null')
				::SetResponse('}')
			EndIf
		
		Else
		�� SetRestFault(400, "body parameter error")
	�� 		lPut := .F.
	
			ConOut("##### [JSON][ERR] " + "Parser 1 com erro" + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
		   	ConOut("Erro a partir: " + SubStr(strJson, (nRetParser+1)))
		EndIf
	Else
		SetRestFault(400, "Erro n�o encontrado empresa para processamento")
		lPut := .F.
	EndIf
/*Else
	conout('ERRO')
	//HTTPSetStatus(422,"ERRO")
	SetRestFault(416, "parametro obrigatorio")
	lPut := .F.
EndIf*/
conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST_PUT_CLIENTES FIM')

Return lPut
�
// O metodo DELETE pode receber parametros por querystring, por exemplo:
// WSMETHOD DELETE WSRECEIVE startIndex, count WSSERVICE clientes
/*WSMETHOD DELETE WSSERVICE clientes
Local lDelete := .T.
�
// Exemplo de retorno de erro
If Len(::aURLParms) == 0
�� SetRestFault(400, "id parameter is mandatory")
�� lDelete := .F.
�
Else
�� // insira aqui o c�digo para opera��o exclus�o
�� // exemplo de retorno de um objeto JSON
�� ::SetResponse('{"id":' + ::aURLParms[1] + ', "name":"clientes"}')
EndIf
Return lDelete
*/

Static Function InsereCli(oJson,aContJson)
Local lRet 	:= .T.
Local z:=x:=0
Local oHeader
Local oContent
Local aErros 		:= {}
Local aCliente	:= {}
Local aCli			:= {}
Local cDoc			:= ''
Local lVldCmp 	:= .T. //Valida��o de campo customizado
Local nTotalPed 	:= 0
Local oRestClient	:= FWRest():New("http://viacep.com.br")
Local cRestResult	:=""
Local aHeader 	:= {}
Local oJsonCep
Local jsonCep 	:= {}
Local nRetCep 	:= 0
Local cTipo 		:= 3
Local oJsonParCep	:= tJsonParser():New()
Local cCod 		:= ""
Local cLoja		:= "01"
Local lNotObrg	:= .F.

SX3->(DbSetOrder(1))
SA1->(DbSetOrder(1))

//SX3->(DbGoTop())
conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST INICIO PROCESSAMENTO DE CLIENTE')
nPosCod:= aScan(aContJson,{|x| UPPER(Alltrim(x[1]))=="A1_COD"})
nPosLj := aScan(aContJson,{|x| UPPER(Alltrim(x[1]))=="A1_LOJA"})
nPosCNPJ := aScan(aContJson,{|x| UPPER(Alltrim(x[1]))=="A1_CGC"})
If nPosCNPJ==0 

Else
	oContent := oJson:CLIENTE
		aEval(aCmpObg,{|x| cCampo := UPPER(x), if(aScan(aContJson,{|y| upper(alltrim(y[1]))==Alltrim(cCampo)})==0,eVal({|| lNotObrg:=.T.,aAdd(aErros,{cCampo,"Campo Obrigatorio"})}),'')})
		If !lNotObrg
			SX3->(DbSeek('SA1'))
			While SX3->(!EOF()) .And. SX3->X3_ARQUIVO=="SA1"
				If ALLTRIM(SX3->X3_CAMPO) $ "A1_CEP"
					conout('teste a1_cep: '+oJson:CLIENTE:A1_CEP)
				EndIf
				If ALLTRIM(SX3->X3_CAMPO) $ cCmpObg
				   	If eVAL(&('{|| oContent:'+SX3->X3_CAMPO+' }'))== Nil .Or. Empty(eVAL(&('{|| oContent:'+SX3->X3_CAMPO+' }')))
				   		aAdd(aErros,{SX3->X3_CAMPO,"Campo obrigatorio"})
				   	Else
					   	If Alltrim(SX3->X3_CAMPO)=="A1_PESSOA"
					   		If(oContent:A1_PESSOA $ "J|F",,aAdd(aErros,{SX3->X3_CAMPO,"Conteudo invalido"}))
					   	ElseIf Alltrim(SX3->X3_CAMPO)=="A1_CEP" 
					   		oRestClient:SetPath("/ws/" + Alltrim(oContent:A1_CEP) + "/json/")
					   		oRestClient:Get(aHeader)
							cRestResult := oRestClient:GetResult()
							conout('cRestResult >>'+cRestResult)
					   		fwjsondeseialize(cRestResult,@oJsonCep)
							lCepParser := oJsonParCep:Json_Parser(cRestResult,Len(cRestResult),@jsonCep,@nRetCep) 
					   		If(Len(jsonCep)>0 .And. aScan(jsonCep,{|x| UPPER(ALLTRIM(x[1]))=="ERRO"})==0,'',aAdd(aErros,{SX3->X3_CAMPO,"Conteudo invalido"}))
				   		EndIf
				   	EndIf
				EndIf 
				If Len(aErros)==0
					If aScan(aContJson,{|x| UPPER(Alltrim(x[1])) == Alltrim(SX3->X3_CAMPO)})>0 
				   		If !empty(eVAL(&('{|| oContent:'+SX3->X3_CAMPO+' }')))
							aadd(aCliente,{SX3->X3_CAMPO   ,If(SX3->X3_TIPO=="C",SubStr(Alltrim(eVAL(&('{|| oContent:'+SX3->X3_CAMPO+' }'))),1,SX3->X3_TAMANHO),;
					   										  If(SX3->X3_TIPO=="N",Val(eVAL(&('{|| oContent:'+SX3->X3_CAMPO+' }'))),;
					   										  If(SX3->X3_TIPO=="D",SToD(eVAL(&('{|| oContent:'+SX3->X3_CAMPO+' }'))),;
					   										  eVAL(&('{|| oContent:'+SX3->X3_CAMPO+' }'))))),Nil})
						EndIf
					EndIf
				EndIf
			SX3->(DbSkip())
			EndDo
		EndIf
		If Len(aErros)==0
			aRetCodCli := StaticCall(U_MATA410,GetCliente,oContent:A1_CGC)
			If aRetCodCli[1]	
				cTipo := 4 //Altera Cadastro
				cCod := aRetCodCli[2]
				cLoja:= aRetCodCli[3]
				aadd(aCliente,{"A1_COD"  ,aRetCodCli[2]  	,Nil}) // Codigo				 
				aadd(aCliente,{"A1_LOJA" ,aRetCodCli[3]  	,Nil}) // Loja
				HTTPSetStatus(200,"OK")	
			Else
				cCod := GetSxeNum("SA1","A1_COD")		
				RollBAckSx8()
				aadd(aCliente,{"A1_COD"  ,cCod  	,Nil}) // Codigo				 
				aadd(aCliente,{"A1_LOJA" ,"01"  	,Nil}) // Loja
				HTTPSetStatus(201,"OK")
			EndIf
			If Len(jsonCep)>0
				IF(aScan(aCliente,{|x| Alltrim(x[1])=="A1_END"})==0		,aadd(aCliente,{"A1_END"		, SubStr(oJsonCep:LOGRADOURO,1,TamSX3("A1_END")[1]),Nil}),)
				IF(aScan(aCliente,{|x| Alltrim(x[1])=="A1_MUN"})==0		,aadd(aCliente,{"A1_MUN"		, SubStr(oJsonCep:LOCALIDADE,1,TamSX3("A1_MUN")[1]),Nil}),)
				IF(aScan(aCliente,{|x| Alltrim(x[1])=="A1_BAIRRO"})==0	,aadd(aCliente,{"A1_BAIRRO"	, SubStr(oJsonCep:BAIRRO,1,TamSX3("A1_BAIRRO")[1]),Nil}),)
				IF(aScan(aCliente,{|x| Alltrim(x[1])=="A1_EST"})==0		,aadd(aCliente,{"A1_EST"		, ALLTRIM(oJsonCep:UF) ,Nil}),)
				IF(aScan(aCliente,{|x| Alltrim(x[1])=="A1_COD_MUN"})==0	,aadd(aCliente,{"A1_COD_MUN", SubStr(oJsonCep:IBGE,3),Nil}),)
			EndIF
			IF aScan(aCliente,{|x| Alltrim(x[1])=="A1_TIPO"})==0
				aadd(aCliente,{"A1_TIPO"	, If(oContent:A1_PESSOA=="J","R",oContent:A1_PESSOA),Nil})
			EndIf
			
			aErros := GerCli(aCliente,cTipo)		
			If Len(aErros)>0
				lRet := .F.
			EndIf
		Else
			lRet := .F.
		EndIf
	
EndIf
Return {lRet,aErros,cCod,cLoja,aCliente}



/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function GerCli(aCliente,cTipo)
Local nX     	:= 0
Local nCount 	:= 0   
Local cLogFile:= "\u_mata030_" + DToS(date()) + StrTran(Time(),":",".") +".LOG" 
Local cLogFolder1:= "\log_ws"
Local cLogFolder2:= "\rest_cliente"
Local aLog 	:= {}
Local aVetor 	:= {}
Local nHandle
Local lRet 	:= .F.  
Local aErros	:={}

PRIVATE lMsErroAuto := .F.
// vari�vel que define que o help deve ser gravado no arquivo de log e que as informa��es est�o vindo � partir da rotina autom�tica.
Private lMsHelpAuto	:= .T.    
// for�a a grava��o das informa��es de erro em array para manipula��o da grava��o ao inv�s de gravar direto no arquivo tempor�rio 
Private lAutoErrNoFile := .T. 

conout('Inicio geracao do Cliente: ')
aEval(aCliente,{|x| conout('campo >> '+x[1]+' - conteudo >>'+x[2])})
MSExecAuto({|x,y| Mata030(x,y)},aCliente,cTipo) //3- Inclus�o, 4- Altera��o, 5- Exclus�o 

If lMsErroAuto	
	Alert("Erro")
Else
	Alert("Ok")
Endif
If lMsErroAuto
	AutoGrLog(SM0->M0_CODIGO+"/"+SM0->M0_CODFIL+ " - CLIENTE: ")
	AutoGrLog(Replicate("-", 20))
conout('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] REST ERRO PROCESSAMENTO EXECAUTO MATA030')
	//Verifica se ja existe pasta para geracao de arquivo de log.
	If !(ExistDir(cLogFolder1))
		If(MakeDir(cLogFolder1)==0,conout('pasta criada com sucesso'),conout('nao foi possivel criar a pasta'+cValToChar(FError())))
	EndIf		
	If !(ExistDir(cLogFolder1+cLogFolder2))
		If(MakeDir(cLogFolder1+cLogFolder2)==0,conout('pasta criada com sucesso'),conout('nao foi possivel criar a pasta'+cValToChar(FError())))
	EndIf
	cLogFile := cLogFolder1 + cLogFolder2 + cLogFile 		
	//fun��o que retorna as informa��es de erro ocorridos durante o processo da rotina autom�tica		
	aLog := GetAutoGRLog()	                                 				
	//efetua o tratamento para validar se o arquivo de log j� existe		
	If !File(cLogFile)		
		If (nHandle := MSFCreate(cLogFile,0)) <> -1
			lRet := .T.			
		EndIf		
	Else
		If (nHandle := FOpen(cLogFile,2)) <> -1
			FSeek(nHandle,0,2)				
			lRet := .T.			
		EndIf		
	EndIf		
	If	lRet
		conout('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] REST ERRO PROCESSAMENTO EXECAUTO MATA030 CLIENTE: ')                                                                                     			
		//grava as informa��es de log no arquivo especificado			
		For nX := 1 To Len(aLog)				
			FWrite(nHandle,aLog[nX]+CHR(13)+CHR(10))
			aAdd(aErros,{"ExecAuto",aLog[nX]})
			conout(StrZero(nX,2)+' | '+aLog[nX])
		Next nX			
		FClose(nHandle)
	Else
		conout('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] REST ERRO PROCESSAMENTO EXECAUTO MATA030 CLIENTE: ')
		For nX := 1 To Len(aLog)				
			aAdd(aErros,{"ExecAuto",aLog[nX]})
			conout(StrZero(nX,2)+' | '+aLog[nX])			
		Next nX		
	EndIf	
Else
	conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST PROCESSAMENTO REALIZADO COM SUCESSO CLIENTE ')
EndIf


Return aErros
