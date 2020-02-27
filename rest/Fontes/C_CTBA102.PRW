#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

#DEFINE cCmpObg  "|C5_SERWEB|C5_TPVENDA|C6_PRODUTO|CT2_VALOR|DOC_PESSOA|CT2_KEY"
#DEFINE aContObg {"C5_SERWEB","C5_TPVENDA","C6_PRODUTO","CT2_VALOR","DOC_PESSOA","CT2_KEY"}
 
WSRESTFUL C_CTBA102 DESCRIPTION "Serviço para inclusao, alteracao e exclusao de pedido de venda."
 
WSDATA count      AS INTEGER
WSDATA startIndex AS INTEGER
 
WSMETHOD POST DESCRIPTION "Atualiza pedido ja integrados." WSSYNTAX "/C_CTBA102/{id}"
 
END WSRESTFUL
 
// O metodo POST pode receber parametros por querystring, por exemplo:
// WSMETHOD POST WSRECEIVE startIndex, count WSSERVICE C_CTBA102
WSMETHOD POST WSSERVICE C_CTBA102
Local lPost := .T.
Local cJson	:= ""
Local aErros	:={} 
Local aRet		:={} 
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
Local aCodEmp := {}
Local _lAuto := .F.

oJsonParser := tJsonParser():New()

conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST_POST INICIO')
If  Len(::aURLParms) > 0 
	aCodEmp:=StaticCall(U_MATA410,GetCodEmp,::aURLParms[1])
	If Len(aCodEmp)>0
		conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] LIMPA AMBIENTE')
		RpcClearEnv()
		conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] MONTA AMBIENTE')
		RpcSetType(3)
		RpcSetEnv(aCodEmp[1],aCodEmp[2])

	   // recupera o body da requisição
		cJson := ::GetContent()
		fwjsondeseialize(cJson,@oJson)
		lRetParser := oJsonParser:Json_Parser(cJson,Len(cJson),@jsonfields,@nRetParser)
		
		aContJson := jsonfields[1][2][2][2]
		If lRetParser .And. Len(aContJson)>0
			conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST_POST JSON RECEBIDO OK')
			aRet := GerLanCtb(oJson,aContJson)
			::SetResponse('{"lancamento":{')
			If Len(aRet[2]) > 0 .AND. !aRet[1]
				aErros:= aRet[2]
				If Len(aRet[4])>0 .And. Len(aRet[5])>0
					If aScan(aContJson,{|x| Alltrim(x[1])=="DOC_PESSOA"})>0
	              	::SetResponse('"DOC_PESSOA":"'+oJson:LANCAMENTO:DOC_PESSOA+'",')
	              EndIf
					For z:=1 To Len(aRet[4])
						::SetResponse(if(z==1,'',','))
	              	::SetResponse(',"'+aRet[4][z][1]+'":"'+ if(Valtype(aRet[4][z][2])=="C",aRet[4][z][2],;
																	  if(Valtype(aRet[4][z][2])=="D",DToS(aRet[4][z][2]),;
																	  if(Valtype(aRet[4][z][2])=="N",Alltrim(str(aRet[4][z][2])),aRet[4][z][2]))) + '"')  					
		         	Next
			     	//::SetResponse('}')
		         	//::SetResponse(',"content":[')
		         	For x:=1 To Len(aRet[5])
			         	::SetResponse(if(x==1,'',','))
			       	::SetResponse('{')
		          		For y:=1 To Len(aRet[5][x])
		          			::SetResponse(if(y==1,'',','))
	              		::SetResponse('"'+aRet[5][x][y][1]+'":"'+if(Valtype(aRet[5][x][y][2])=="C",aRet[5][x][y][2],;
																	  if(Valtype(aRet[5][x][y][2])=="D",DToS(aRet[5][x][y][2]),;
																	  if(Valtype(aRet[5][x][y][2])=="N",Alltrim(str(aRet[5][x][y][2])),aRet[5][x][y][2]))) + '"')  					
		         		Next 
		         		::SetResponse('}')
	    			Next
	    		Else
	    			For i := 1 To Len(aContJson)
	    				::SetResponse(if(i==1,'',','))
	    				::SetResponse('"'+aContJson[i][1]+'":"'+ if(Valtype(aContJson[i][2])=="C",aContJson[i][2],;
																	  if(Valtype(aContJson[i][2])=="D",DToS(aContJson[i][2]),;
																	  if(Valtype(aContJson[i][2])=="N",Alltrim(str(aContJson[i][2])),aContJson[i][2]))) + '"')	
	    			Next
	    		  	::SetResponse('}')
		         	
		       EndIF
    			
				::SetResponse(',"errors":[')
				For i:=1 To Len(aErros)
					If ALLTRIM(aErros[i][1])=="ExecAuto"
						_lAuto := .T.
						cRet += if(i==1,'{"field":"'+aErros[i][1]+'","description":"','')
						cRet += '|' + StrZero(i,2) + ' | ' + StrTran(aErros[i][2],CRLF,"") 
					Else
						cRet += if(i==1,'',',')
						cRet += '{"field":"'+aErros[i][1]+'","description":"'+aErros[i][2]+'"}'
					EndIf
				Next
				cRet += if(_lAuto,'"}','')
				::SetResponse(cRet)
				::SetResponse(']')
				//::SetResponse('}')
              //::SetResponse('}')
				HTTPSetStatus(400)
				//SetRestFault(4,'[' + cRet + ']')
				//lPost := .F.
			Else
				::SetResponse('"DOC_PESSOA":"'+oJson:LANCAMENTO:DOC_PESSOA+'"')
				For z:=1 To Len(aRet[4])
	             	::SetResponse(',"'+aRet[4][z][1]+'":"'+if(Valtype(aRet[4][z][2])=="C",aRet[4][z][2],;
																  if(Valtype(aRet[4][z][2])=="D",DToS(aRet[4][z][2]),;
																  if(Valtype(aRet[4][z][2])=="N",Alltrim(str(aRet[4][z][2])),aRet[4][z][2]))) + '"')  					
		       Next
//::SetResponse('}')
		       //::SetResponse(',"content":')
		       For x:=1 To Len(aRet[5])
		       	//::SetResponse(if(x==1,'',','))
		       	//::SetResponse('{')
		       	For y:=1 To Len(aRet[5][x])
		       		//::SetResponse(if(y==1,'',','))
	              	::SetResponse(',"'+aRet[5][x][y][1]+'":"'+if(Valtype(aRet[5][x][y][2])=="C",aRet[5][x][y][2],;
																	  if(Valtype(aRet[5][x][y][2])=="D",DToS(aRet[5][x][y][2]),;
																	  if(Valtype(aRet[5][x][y][2])=="N",Alltrim(str(aRet[5][x][y][2])),aRet[5][x][y][2]))) + '"')  					
		       	Next 
		       	::SetResponse(',"CT2_UNQ":"'+CT2->(CT2_FILIAL+DToS(CT2_DATA)+CT2_LOTE+CT2_SBLOTE+CT2_DOC)+'"')
		       	::SetResponse('}')	
	    		Next 
	    		::SetResponse('')
				::SetResponse(',"error":null')
			EndIf
			::SetResponse('}')
		Else
		   SetRestFault(400, "body parameter error")
	   		lPost := .F.
	
			ConOut("##### [JSON][ERR] " + "Parser 1 com erro" + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
		   	ConOut("Erro a partir: " + SubStr(strJson, (nRetParser+1)))
		EndIf
	Else
		SetRestFault(400, "parametro invalido")
		lPost := .F.
	EndIf
Else
	SetRestFault(400, "parametro obrigatorio")
	lPost := .F.
EndIf
conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST_POST FIM')

Return lPost
 

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\/\/\/\/*/

Static Function GerLanCtb(oJson,aContJson,cLanPad)
Local lRet 	:= .T.
Local z:=x:=0
Local oHeader
Local oContent
Local aErros 	:= {}
Local aCabec	:= {}
Local aItens	:= {}
Local aCli		:= {}
Local cDoc		:= ''

//-----------------------------
Local lRet            := .T.
Local aLinha         := {}
lOCAL nLinha        := 1
Local aDocPessoa		:= {}			 


Private _aDados			:= {}

DEFAULT cLanPad := "0M1"

CT5->(DbSetOrder(1))
//SX3->(DbGoTop())
conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST INICIO PROCESSAMENTO DE CONTABILIZACAO')

aEval(aContObg,{|x| cCampo:=x, if(aScan(aContJson,{|y| upper(alltrim(y[1]))==Alltrim(cCampo)})==0,eVal({|| lNotObrg:=.T.,aAdd(aErros,{cCampo,"Campo Obrigatorio"})}),'')})
If Len(aErros)>0
	lRet := .F.
Else
	ConOut('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] Gerando _aDados')
/*
aDados[1] => C5_SERWEB
aDados[2] => C6_PRODUTO
aDados[3] => C5_TPVENDA
aDados[4] => CT2_VALOR
aDados[5] => CT2_KEY
aDados[6] => DOC_PESSOA
*/	

	SC5->(DbSetOrder(1))
	SC6->(DbSetOrder(1))
	SX5->(DbSetOrder(1))
	ZZ3->(DbSetOrder(1))
	SB1->(DbSetOrder(1))
	
	oContent := oJson:LANCAMENTO
	aDocPessoa := StaticCall(U_MATA410,GetCliente,oContent:DOC_PESSOA) 
	If aDocPessoa[1]
		If(Empty(oContent:C5_SERWEB) 	.Or. !SX5->(DbSeek(xFilial("SX5") + '01' + oContent:C5_SERWEB ))	,aAdd(aErros,{"C5_SERWEB"	,"Conteudo invalido"}),)
		If(Empty(oContent:C6_PRODUTO) 	.Or. !SB1->(DbSeek(xFilial("SB1") + oContent:C6_PRODUTO ))			,aAdd(aErros,{"C6_PRODUTO"	,"Conteudo invalido"}),)
		If(Empty(oContent:C5_TPVENDA) 	.Or. !ZZ3->(DbSeek(xFilial("ZZ3") + oContent:C5_TPVENDA))			,aAdd(aErros,{"C5_TPVENDA"	,"Conteudo invalido"}),)
		If(Empty(oContent:CT2_VALOR)	.Or. Val(oContent:CT2_VALOR) <= 0										,aAdd(aErros,{"CT2_VALOR"	,"Conteudo invalido"}),)
		If(Empty(oContent:CT2_KEY) 																					,aAdd(aErros,{"CT2_KEY"		,"Conteudo invalido"}),)
		
		If Len(aErros)==0
			ConOut('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] VALIDACAO DE DADOS OK.')
			aAdd(_aDados,{"C5_SERWEB"	,oContent:C5_SERWEB})
			aAdd(_aDados,{"C6_PRODUTO"	,oContent:C6_PRODUTO})
			aAdd(_aDados,{"C5_TPVENDA"	,oContent:C5_TPVENDA})
			aAdd(_aDados,{"CT2_VALOR"	,oContent:CT2_VALOR})
			aAdd(_aDados,{"CT2_KEY"		,oContent:CT2_KEY})
			aAdd(_aDados,{"DOC_PESSOA"	,aDocPessoa[2]+aDocPessoa[3]})
					
			ConOut('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] GERANDO DOCUMENTO CONTABIL.')
			 
			aCabec := {}
			aItem := {}
			 
			aAdd(aCabec,  {'DDATALANC'		,Date()			,NIL})
			aAdd(aCabec,  {'CLOTE'			,'WEBMED'			,NIL})
			aAdd(aCabec,  {'CSUBLOTE'		,'001'				,NIL})
			//aAdd(aCab,  {'CDOC'			,'000001'			,NIL})
			If aScan(aContJson,{|y| upper(alltrim(y[1]))=="CPADRAO"})>0
				cLanPad := oContent:CPADRAO
			EndIf
			aAdd(aCabec,{'CPADRAO'		,cLanPad	,NIL})
			aAdd(aCabec,  {'NTOTINF'		,Val(oContent:CT2_VALOR)	,NIL})
			aAdd(aCabec,  {'NTOTINFLOT'	,0					,NIL})
			    
			//aAdd(aLinha,{'CT2_FILIAL'	,'0101   '			,NIL})
			IF CT5->(DbSeek(xFilial("CT5")+cLanPad))
				While CT5->(!EOF() .And. CT5_LANPAD == cLanPad) 
				CONOUT('CTBA102 LINHA'+STRZERO(nLinha,3))
					If &(CT5->CT5_VLR01) > 0
						aAdd(aLinha,{'CT2_LINHA'		, StrZero(nLinha,TamSX3("CT2_LINHA")[1]),NIL})
						aAdd(aLinha,{'CT2_DC'		,CT5->CT5_DC			,NIL})
						aAdd(aLinha,{'CT2_KEY'		,oContent:CT2_KEY		,NIL})
						aAdd(aLinha,{'CT2_HIST'		,&(CT5->CT5_HIST)		,NIL})
						aAdd(aLinha,{'CT2_ORIGEM'	,&(CT5->CT5_ORIGEM)	,NIL})
						aAdd(aLinha,{'CT2_MOEDLC'	,IF(EMPTY(CT5->CT5_MOEDLC),"01",CT5->CT5_MOEDLC)		,NIL})
						If CT5->CT5_DC $ "1|3"
							aAdd(aLinha,{'CT2_DEBITO'	,If(!EMPTY(&(CT5->CT5_DEBITO))	,&(CT5->CT5_DEBITO)	,'')	,NIL})
							aAdd(aLinha,{'CT2_CCD'		,If(!EMPTY(&(CT5->CT5_CCD))		,&(CT5->CT5_CCD)		,'')	,NIL})
							aAdd(aLinha,{'CT2_ITEMD'		,If(!EMPTY(&(CT5->CT5_ITEMD))	,&(CT5->CT5_ITEMD)	,'')	,NIL})
							aAdd(aLinha,{'CT2_CLVLDB'	,If(!EMPTY(&(CT5->CT5_CLVLDB))	,&(CT5->CT5_CLVLDB)	,'')	,NIL})
						EndIf
						If CT5->CT5_DC $ "2|3"
							aAdd(aLinha,{'CT2_CREDIT'	,If(!EMPTY(&(CT5->CT5_CREDIT))	,&(CT5->CT5_CREDIT)	,'')	,NIL})
							aAdd(aLinha,{'CT2_CCC'		,If(!EMPTY(&(CT5->CT5_CCC))		,&(CT5->CT5_CCC)		,'')	,NIL})
							aAdd(aLinha,{'CT2_ITEMC'		,If(!EMPTY(&(CT5->CT5_ITEMC))	,&(CT5->CT5_ITEMC)	,'')	,NIL})
							aAdd(aLinha,{'CT2_CLVLCR'	,If(!EMPTY(&(CT5->CT5_CLVLCR))	,&(CT5->CT5_CLVLCR)	,'')	,NIL})
						EndIf
						aAdd(aLinha,{'CT2_VALOR'		,Round(VAL(oContent:CT2_VALOR),TAMSX3("CT2_VALOR")[2])	,NIL})
							
						aAdd(aLinha,{'CT2_ROTINA'	,'WEB_REST'		,NIL})
					
						aAdd(aItens,aLinha)
						nLinha++		
					EndIf
				CT5->(DbSkip())
				EndDo
				aLinha:={}
			
				IncLanCtb(aCabec,aItens,3)
			Else
				ConOut('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] VALIDACAO DE DADOS ERRO - LP NAO EXISTE.')
				aAdd(aErros,{"CLANPAD"		,"Conteudo invalido"})
				lRet:=.F.
			EndIf
		Else
			lRet := .F. 
			ConOut('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] VALIDACAO DE DADOS ERRO.')
		EndIf
	Else
		ConOut('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] VALIDACAO DE DADOS ERRO - DADOS CLIENTE.')
		aAdd(aErros,{"DOC_PESSOA"		,"Conteudo invalido"})
		lRet:=.F.
	EndIf
EndIf

Return {lRet,aErros,cDoc,aCabec,aItens}

Static Function IncLanCtb(aCabec,aItens,nTipo)
Local nX     	:= 0
Local nCount 	:= 0   
Local cLogFile:= "\C_CTBA102_" + DToS(date()) + StrTran(Time(),":",".") +".LOG" 
Local cLogFolder1 := "\log_ws"
Local cLogFolder2 := "\rest_ctb"
Local aLog 	:= {}
Local aVetor 	:= {}
Local nHandle
Local lRet 	:= .F.  
Local aErros	:={}
 
// variável de controle interno da rotina automatica que informa se houve erro durante o processamento
PRIVATE lMsErroAuto := .F.
// variável que define que o help deve ser gravado no arquivo de log e que as informações estão vindo à partir da rotina automática.
Private lMsHelpAuto	:= .T.    
// força a gravação das informações de erro em array para manipulação da gravação ao invés de gravar direto no arquivo temporário 
Private lAutoErrNoFile := .T. 

lMsErroAuto := .F.    	
lRet := .F.	
	
conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST INICIO PROCESSAMENTO EXECAUTO CTBA102')


MSExecAuto({|x, y,z| CTBA102(x,y,z)}, aCabec ,aItens, 3)

If lMsErroAuto
	AutoGrLog(SM0->M0_CODIGO+"/"+SM0->M0_CODFIL+ " - Contabilizacao. ")
	AutoGrLog(Replicate("-", 20))
conout('[USER][ERRO] [' + DToC(Date())+ ' - ' + Time() + '] REST ERRO PROCESSAMENTO EXECAUTO CTBA102')
	//Verifica se ja existe pasta para geracao de arquivo de log.
	If !(ExistDir(cLogFolder1))
		If(MakeDir(cLogFolder1)==0,conout('pasta criada com sucesso'),conout('nao foi possivel criar a pasta'+cValToChar(FError())))
	EndIf		
	If !(ExistDir(cLogFolder1+cLogFolder2))
		If(MakeDir(cLogFolder1+cLogFolder2)==0,conout('pasta criada com sucesso'),conout('nao foi possivel criar a pasta'+cValToChar(FError())))
	EndIf
	cLogFile := cLogFolder1 + cLogFolder2 + cLogFile		
	
	//cLogFile := cLogFolder + "\C_CTBA102_" + DToS(date()) + StrTran(Time(),":",".") + Alltrim(cDoc)+".LOG"		
	//função que retorna as informações de erro ocorridos durante o processo da rotina automática		
	aLog := GetAutoGRLog()	                                 				
	//efetua o tratamento para validar se o arquivo de log já existe		
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
		conout('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] REST ERRO PROCESSAMENTO EXECAUTO CTBA102 - consulte arquivo de log.')                                                                                     			
		//grava as informações de log no arquivo especificado			
		For nX := 1 To Len(aLog)				
			FWrite(nHandle,aLog[nX]+CRLF)
			aAdd(aErros,{"ExecAuto",aLog[nX]})
			conout(StrZero(nX,2)+' | '+aLog[nX])
		Next nX
		FWrite(nHandle,Replicate("-", 20)+CRLF)
		aeVAL(aCabec,{|x| conout(x[1]+' >> '+ If(valtype(x[2])=="C",x[2],;
					   					  If(valtype(x[2])=="N",alltrim(str(x[2])),;
					   					  If(valtype(x[2])=="D",dToS(x[2]),;
					   										  x[2]))))})
		FWrite(nHandle,Replicate("-", 20)+CRLF)
		aeVAL(aItens,{|x| aeval(x,{|y| conout(y[1]+' >> '+ If(valtype(y[2])=="C",y[2],;
					   					  If(valtype(y[2])=="N",alltrim(str(y[2])),;
					   					  If(valtype(y[2])=="D",dToS(y[2]),;
					   										  y[2]))))})})
		FWrite(nHandle,Replicate("-", 20))							
		FClose(nHandle)
	Else
		conout('[USER][ERRO] ['+DToC(Date())+' - '+Time()+'] REST ERRO PROCESSAMENTO EXECAUTO CTBA102 . ')
		For nX := 1 To Len(aLog)				
			aAdd(aErros,{"ExecAuto",aLog[nX]})
			conout(StrZero(nX,2)+' | '+aLog[nX])			
		Next nX		
	EndIf	
Else
	conout('[USER][INFO] ['+DToC(Date())+' - '+Time()+'] REST PROCESSAMENTO REALIZADO COM SUCESSO CONTABILIZACAO')
EndIf

Return aErros

