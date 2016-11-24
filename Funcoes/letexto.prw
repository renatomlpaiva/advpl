#Include 'Protheus.ch'

#DEFINE cFileTxt "C:\Users\totvs.renato\Documents\script.txt"

User Function letexto(cFile)
Local oTXTFile
Local cLine := ''
Local nLines := 0
Local nTimer

DEFAULT cFile := ""
nTimer := seconds()

cFile := If(Empty(cFile) ,cFileTxt,cFile)

oTXTFile := UFILEREAD():New(cFile,CRLF,1000000)
If !oTXTFile:Open()
  MsgStop(oTXTFile:GetErrorStr(),"OPEN ERROR")
Else
	While oTXTFile:ReadLine(@cLine)
		conout(len(cLine))
	 	conout(left(cLine,20))
	  nLines++
	Enddo
	oTXTFile:Close()
	MsgInfo("Read " + cValToChar(nLines)+" line(s) in "+str(seconds()-nTimer,12,3)+' s.',"Using UFILEREAD")
EndIf
Return