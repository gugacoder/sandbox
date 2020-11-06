@rem
@rem Script de instalacao de ferramentas e dependencias do projeto.
@rem

rem Baixando o gerador de setup do Migrant
migrant.bootstrap.exe

rem Baixando a ferramenta de automação
svn export "https://serverpro.processa.com/svn/fabrica/tools/toolset/Dist/toolset.exe" . --force
@if errorlevel 1 (
  @echo.
  @echo.[ERR]Nao foi possivel baixar a ferramenta de automacao: toolset.exe
  @pause
  @exit /b %errorlevel%
)

rem Baixando as ferramentas usadas pelo toolset
@rem Nao critico. Falhas podem ser ignoradas.
toolset update-toolchain

@echo.
@echo.[OK]Feito!
@pause
