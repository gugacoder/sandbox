@rem
@rem Script de compilação e geração da distribuição do projeto.
@rem

if not exist toolset.exe echo | call make-install-deps.bat
@if errorlevel 1 (
  @echo.
  @echo.[ERR]As ferramentas de apoio nao estao disponiveis. Execute `make-install-deps.bat' para obte-las.
  @pause
  @exit /b %errorlevel%
)

rem Gerando o setup do módulo
migrant.exe make --output-dir Dist --force
@if errorlevel 1 (
  @echo.
  @echo.[ERR]Nao foi possivel gerar o pacote.
  @pause
  @exit /b %errorlevel%
)

@echo.
@echo.[OK]Feito!
@pause
