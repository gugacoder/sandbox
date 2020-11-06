@rem
@rem Script para fechamento da versao do projeto.
@rem
@rem O script executa estas etapas:
@rem 1. Gera uma pasta de versao em /tags/x.x.x
@rem 2. Gera uma pasta /tags/latest apontando para esta nova versao.
@rem
@rem O script falha se houverem recursos não-commitados.
@rem

if not exist toolset.exe echo | call make-install-deps.bat
@if errorlevel 1 (
  @echo.
  @echo.[ERR]Nao foi possivel baixar a ferramenta: toolset.exe
  @pause
  @exit /b %errorlevel%
)

rem Fechando a versao com a copia para a pasta /tags.
toolset tag
@if errorlevel 1 (
  @echo.
  @echo.[ERR]Nao foi possivel fechar a versao.
  @pause
  @exit /b %errorlevel%
)

rem Criando versao latest na pasta /tags
toolset tag --make-latest
@if errorlevel 1 (
  @echo.
  @echo.[ERR]Nao foi possivel criar a versao latest.
  @pause
  @exit /b %errorlevel%
)

@echo.
@echo.[OK]Feito!
@pause
