# Diagnóstico e Manutenção Windows V2.0

Kit profissional de diagnóstico e manutenção para computadores Windows, desenvolvido para uso técnico.

## Status

**Versão V2.0 — funcional e em evolução.**

## Tecnologias e linguagens

- PowerShell — lógica principal dos diagnósticos e módulos de manutenção.
- Batch (.bat) — inicialização e elevação para Administrador.
- TXT — relatórios e documentação.
- WinGet — instalação/atualização opcional de ferramentas externas.

## Arquivos principais

- `Diagnostico_V2.bat` — inicializador.
- `Diagnostico_V2.ps1` — sistema principal de diagnóstico.
- `README_V2.0.txt` — documentação operacional.

## Recursos

- Diagnóstico completo ou por módulo.
- Verificações de integridade do Windows com SFC e DISM.
- Diagnóstico de armazenamento e SMART quando suportado.
- Sensores de temperatura, fans, tensão, carga e clocks quando suportados pelo hardware.
- Relatório consolidado com níveis `CRÍTICO > ERRO > ATENÇÃO > OK`.
- Geração de relatórios na área de trabalho do usuário.
- Instalação de ferramentas opcionais somente após confirmação do técnico.

## Segurança

- Não executa `chkdsk /f` ou `/r` automaticamente.
- Não altera drivers automaticamente.
- Não inicia ou interrompe serviços automaticamente.
- Não altera configurações do Defender/Firewall.
- Operações de reparo e instalação exigem confirmação.

## Observação

A disponibilidade de informações de SMART e sensores de temperatura depende do controlador, driver, firmware e hardware do computador.
