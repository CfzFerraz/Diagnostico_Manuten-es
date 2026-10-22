KIT PROFISSIONAL DE DIAGNOSTICO WINDOWS V2.0

Arquivos principais:
- Diagnostico_V2.bat
- Diagnostico_V2.ps1

EXECUCAO
1. Execute Diagnostico_V2.bat.
2. O BAT solicita elevacao de Administrador.
3. Escolha Diagnostico Completo ou um modulo especifico.
4. Cada modulo gera um TXT em %USERPROFILE%\Desktop\Diagnosticos_PC.

FERRAMENTAS OPCIONAIS
- smartmontools / smartctl: SMART detalhado de HDD, SSD e NVMe.
- Libre Hardware Monitor: sensores de temperatura, fans, tensao, carga e clocks quando suportados pelo hardware.

As ferramentas nao sao instaladas automaticamente. O menu [33] permite instalar/atualizar com WinGet somente apos confirmacao do tecnico.

INTEGRIDADE DO WINDOWS
O modulo primeiro verifica SFC /verifyonly e DISM /CheckHealth.
Se houver indicios e a sessao estiver elevada, pergunta se deve executar SFC /scannow.
Se necessario, oferece DISM /RestoreHealth e depois SFC /scannow novamente.
Por fim, refaz SFC /verifyonly e DISM /CheckHealth para validar o resultado.

SEGURANCA
- Nenhum chkdsk /f ou /r e executado automaticamente.
- Nenhum driver e alterado automaticamente.
- Nenhum servico e iniciado/parado automaticamente.
- Nenhuma configuracao do Defender/Firewall e alterada.
- Instalacao de ferramentas externas exige confirmacao.
- Operacoes de reparo do Windows exigem confirmacao.

STATUS GERAL
O relatorio consolidado agrega os modulos pela hierarquia:
CRITICO > ERRO > ATENCAO > OK

OBSERVACAO
A disponibilidade de sensores SMART/temperatura depende do controlador, driver, firmware e hardware. Ausencia de um sensor nao e tratada como temperatura inventada.
