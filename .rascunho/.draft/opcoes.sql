
"DECLARE @ENCARGOS DECIMAL(18,4) " & _
        "DECLARE @TIPOESTOQUE AS INT " & 
        "DECLARE @RECALCULA AS NVARCHAR(5) " & _
        "DECLARE @RAMOPS AS INT "

    strSQL = strSQL & 
        "SELECT @TIPOESTOQUE = DFvalor FROM TBopcoes WITH (NOLOCK) WHERE DFcodigo = 420 " & 
        "SELECT @RECALCULA = DFvalor FROM TBopcoes WITH (NOLOCK) WHERE DFcodigo = 995 " & _
        "SELECT @RAMOPS = DFvalor FROM TBopcoes WITH (NOLOCK) WHERE DFcodigo = 337 " & 
        "SELECT @ENCARGOS = REPLACE(DFvalor,',','.') FROM TBopcoes WITH (NOLOCK) WHERE DFcodigo = 551 "