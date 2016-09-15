USER FUNCTION CT010ATU()

local dDataFim := ctod("  /  /  ")

aParam := paramixb


if aParam[4] == 2          
  
	for i := 1 to len(aParam[2])
		if (aParam[2][i][4] == "4")
			dDataFim := aParam[2][i][3]
		endif
	next i 
	
	
	if !empty(dDataFim)

		PUTMV("MV_DATAFIN",dtoc(dDataFim))
		PUTMV("MV_DATAFIS",dtoc(dDataFim))
		
	endif
	
endif

RETURN()
