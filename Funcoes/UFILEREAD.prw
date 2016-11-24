#include 'protheus.ch'

#define DEFAULT_FILE_BUFFER 4096
CLASS UFILEREAD FROM LONGNAMECLASS
  DATA nHnd as Integer
  DATA cFName as String
  DATA cFSep as String
  DATA nFerror as Integer
  DATA nOsError as Integer
  DATA cFerrorStr as String
  DATA nFSize as Integer
  DATA nFReaded as Integer
  DATA nFBuffer as Integer
  DATA _Buffer as Array
  DATA _PosBuffer as Integer
  DATA _Resto as String
  // Metodos Pubicos
  METHOD New()
  METHOD Open()
  METHOD Close()
  METHOD GetFSize()
  METHOD GetError()
  METHOD GetOSError()
  METHOD GetErrorStr()
  METHOD ReadLine()
  // Metodos privados
  METHOD _CleanLastErr()
  METHOD _SetError()
  METHOD _SetOSError()
ENDCLASS

METHOD New( cFName , cFSep , nFBuffer ) CLASS UFILEREAD
DEFAULT cFSep := CRLF
DEFAULT nFBuffer := DEFAULT_FILE_BUFFER
::nHnd := -1
::cFName := cFName
::cFSep := cFSep
::_Buffer := {}
::_Resto := ''
::nFSize := 0
::nFReaded := 0
::nFerror := 0
::nOsError := 0
::cFerrorStr := ''
::_PosBuffer := 0
::nFBuffer := nFBuffer
Return self

METHOD Open( iFMode ) CLASS UFILEREAD
DEFAULT iFMode := 0
::_CleanLastErr()
If ::nHnd != -1
 _SetError(-1,"Open Error - File already open")
 Return .F.
Endif
// Abre o arquivo
::nHnd := FOpen( ::cFName , iFMode )
If ::nHnd < 0
 _SetOSError(-2,"Open File Error (OS)",ferror())
Return .F.
Endif
// Pega o tamanho do Arquivo
::nFSize := fSeek(::nHnd,0,2)

// Reposiciona no inicio do arquivo
fSeek(::nHnd,0)
Return .T.

METHOD Close() CLASS UFILEREAD
::_CleanLastErr()
If ::nHnd == -1
 _SetError(-3,"Close Error - File already closed")
Return .F.
Endif
// Close the file
fClose(::nHnd)
// Clean file read cache 
aSize(::_Buffer,0)
::_Resto := ''
::nHnd := -1
::nFSize := 0
::nFReaded := 0
::_PosBuffer := 0
Return .T.

METHOD ReadLine( /*@*/ cReadLine ) CLASS UFILEREAD
Local cTmp := ''
Local cBuffer
Local nRPos
Local nRead
// Incrementa o contador da posi��o do Buffer
::_PosBuffer++
If ( ::_PosBuffer <= len(::_Buffer) )
 // A proxima linha j� est� no Buffer ...
 // recupera e retorna
 cReadLine := ::_Buffer[::_PosBuffer]
 Return .T.
Endif
If ( ::nFReaded < ::nFSize )
  // Nao tem linha no Buffer, mas ainda tem partes
  // do arquivo para ler. L� mais um peda�o
  nRead := fRead(::nHnd , @cTmp, ::nFBuffer)
  if nRead < 0
    _SetOSError(-5,"Read File Error (OS)",ferror())
    Return .F.
  Endif
  // Soma a quantidade de bytes lida no acumulador
  ::nFReaded += nRead
  // Considera no buffer de trabalho o resto
  // da ultima leituraa mais o que acabou de ser lido
  cBuffer := ::_Resto + cTmp
  // Determina a ultima quebra
  nRPos := Rat(::cFSep,cBuffer)
  If nRPos > 0
    // Pega o que sobrou apos a ultima quegra e guarda no resto
    ::_Resto := substr(cBuffer , nRPos + len(::cFSep))
    // Isola o resto do buffer atual
    cBuffer := left(cBuffer , nRPos-1 )
  Else
    // Nao tem resto, o buffer ser� considerado inteiro
    // ( pode ser final de arquivo sem o ultimo separador )
    ::_Resto := ''
  Endif
 // Limpa e Recria o array de cache
 // Por default linhas vazias s�o ignoradas
 // Reseta posicionamento de buffer para o primeiro elemento 
 // E Retorna a primeira linha do buffer 
 aSize(::_Buffer,0)
 ::_Buffer := StrTokArr2( cBuffer , ::cFSep )
 ::_PosBuffer := 1
 cReadLine := ::_Buffer[::_PosBuffer]
 Return .T.
Endif
// Chegou no final do arquivo ...
::_SetError(-4,"File is in EOF")
Return .F.

METHOD GetError() CLASS UFILEREAD
Return ::nFerror

METHOD GetOSError() CLASS UFILEREAD
Return ::nOSError

METHOD GetErrorStr() CLASS UFILEREAD
Return ::cFerrorStr

METHOD GetFSize() CLASS UFILEREAD
Return ::nFSize

METHOD _SetError(nCode,cStr) CLASS UFILEREAD
::nFerror := nCode
::cFerrorStr := cStr
Return

METHOD _SetOSError(nCode,cStr,nOsError) CLASS UFILEREAD
::nFerror := nCode
::cFerrorStr := cStr
::nOsError := nOsError
Return

METHOD _CleanLastErr() CLASS UFILEREAD
::nFerror := 0
::cFerrorStr := ''
::nOsError := 0
Return