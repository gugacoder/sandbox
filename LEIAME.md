Mlogic.Gestor
=============

Pacote de scripts do GESTOR do MERCADOLOGIC, um aplicativo componente do MERCADOLOGIC
escrito em C# em base de dados SQLSERVER que acompanha o DIRECTOR e gerencia todas as
inst�ncias do CONCENTRADOR e dos PDVs do MERCADOLOGIC de forma centralizada.

A base de dados `DBmercadologic`, no SQLSERVER, cont�m views para o `DBdirector` e
vice-versa. � esperado que os aplicativos do MERCADOLOGIC e do DIRECTOR acessem os
objetos da base `DBmercadologic` atrav�s das views instaladas no `DBdirector`, isto
�, o acesso direto � base `DBmercadologic` n�o � permitido.

---
Nov/2020  
Guga Coder
