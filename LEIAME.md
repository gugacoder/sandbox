Mlogic.Gestor
=============

Pacote de scripts do GESTOR do MERCADOLOGIC, um aplicativo componente do MERCADOLOGIC
escrito em C# em base de dados SQLSERVER que acompanha o DIRECTOR e gerencia todas as
instâncias do CONCENTRADOR e dos PDVs do MERCADOLOGIC de forma centralizada.

A base de dados `DBmercadologic`, no SQLSERVER, contém views para o `DBdirector` e
vice-versa. É esperado que os aplicativos do MERCADOLOGIC e do DIRECTOR acessem os
objetos da base `DBmercadologic` através das views instaladas no `DBdirector`, isto
é, o acesso direto à base `DBmercadologic` não é permitido.

---
Nov/2020  
Guga Coder
