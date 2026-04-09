# Workflow Flexivel
https://www.youtube.com/watch?v=DjWucp2X9T0  
https://www.youtube.com/watch?v=MQa4gMWlIic

BLOG Buscar responsáveis para aprovar work item    
https://community.sap.com/t5/technology-blog-posts-by-members/determining-sap-flexible-workflow-agents-with-custom-responsibility-rules/ba-p/13558459  

BLOG (outro) Como criar Workflow flexível     
https://community.sap.com/t5/technology-blog-posts-by-sap/flexible-workflows-custom-flexible-workflow-scenario-for-re-fx-contract/ba-p/13476198  

## Apps
1. Administrar regras de responsabilidade  

2. Administrar contextos de responsabilidade  
  
3. Administrar workflows (Configurar WF Etapa)  

## Esquema Config responsáveis e novo campo custom p/ config wf
<img width="1742" height="998" alt="image" src="https://github.com/user-attachments/assets/37614e6e-92fb-4272-b0f3-aeb5c052839c" />

Main transactions
- SWEQADM  Administração da fila de eventos (Event Queue Administration)
- PFTC  Create/maintain workflow tasks (Standard & Custom)
- SWDD  Workflow Builder – create/change workflows
- SWDD_CONFIG  Workflow configuration for flexible workflows
- SWU3  Automatic Workflow Customizing (setup)
- SWEL  Event log – check if events are triggered
- SWELS  Switch event log on/off
- SWIA  Display/administrate work itemsSWI1Work item selection (monitoring)
- SWI2_DIAG  Workflow diagnosis / error analysis
- SWI2_FREQ  Find frequently occurring workflow errors
- SWUE  Generate WF Event
- SWPR  Restart workflow after error
- SWPC  Continue workflow after error
- SWETYPV  Link events to workflow (event coupling)
- SWE2  Event type linkage overview
- SWEQPR  Processamento da fila de eventos


WF Flex
- SWDD_SCENARIO
- SWFVISU
- /n/UI2/FLP Home / Launchpad

## SCRIPT-CRIAR-WORFLOW-FLEXÍVEL

- ok	Descobrir Quais são as Tabelas Transparentes (Funcional + Copilot)
	- QMEL	(Header)
	- QMFE	(Item)
	- QMIH	(Dados)
- ok	Descobrir Quais são as CDS VIEWS (Copilot + Eclipse)
	- I_MaintenanceNotification 	(Header)
	- I_MaintNotificationItemData	(Item)
	- I_PMNotifMaintenanceData 	(Dados)
- ok	Criar Classe ABAP (SE24) ZCL_WF_NOTA_MANUTENCAO
	- ok	Criar Constructor
	- ok	Copiar método WORKITEM_EXECUTE (Instance, pub)
	- ok	Copiar método GET_CLASS_NAME (Instance, protected)
	- ok	Copiar método EXECUTE (Instance, pub)
	- ok	Criar parâmetros com tabelas corretas
- ok	Criar Workflow Flexível (/nSWDD_SCENARIO)
	- ok	WS99900021
	- ok	Criar variáveis do workflow
	- ok	Criar tarefa de Aprovação
	- nok	Criar Condições
		- ok	Tipo de nota	QMEL-QMART
		- ok	TIPO DE GRUPO 	QMIH-INGRP
		- ok	CENTRO 			QMIH-IWERK
	- ok	Criar Regra de busca de repsonsáveis
		- INGRP+Code
		- ok	App Administrar contextos de responsabilidade
		- ok	Administrar regras de responsabilidade
		- ok	Criar BADI Busca Responsáveis
- ok	Implementar BADI de Disparo NOTIF_EVENT_POST
	- ok	Z_PM_NOTI_WS99900021 Implementação de BADI
	- ok	ZCL_IM_PM_NOTI_WS99900021 Classe ABAP da Implementação de BADI
	- ok	Criar método para disparo (trigger_wf)
	- ok	Criar método para CANCEL (cancel_wf)
	- ok	Criar Função para Disparo ZPMF0005 (+ STATUS_CHANGE_INTERN)
	- ok	Criar Função para CANCEL ZPMF0006
	- ok	Criar Função EXPORT ZWWFF2057
	- ok	Criar Função IMPORT ZWWFF2058
- ok	Criar Classes de CALLBACK
		- ok	ZCL_SWF_FLEX_NOTA_DEF
		- ok	ZCL_SWF_FLEX_NOTA_RUN
	- ok	ZCL_SWF_FLEX_NOTA_RUN-RESULT_CALLBACK()
		- ok	Criar Método p/ Troca de STATUS CLASSE (ZCL_WF_NOTA_MANUTENCAO=>SET_DOCUMENT_AS_APPROVED( STATUS_CHANGE_INTERN ) )
- nok	Botão GOS BADI GOS_MULT_PUBLISH
