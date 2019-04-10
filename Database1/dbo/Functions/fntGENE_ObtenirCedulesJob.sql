/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntGENE_ObtenirCedulesJob
Nom du service		: Obtenir les cédules d’une job 
But 				: Obtenir les cédules d’exécutions unitaires d’une job SQL.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						vcNom_Job					Nom de la job SQL.  Le nom est requis sinon les champs de sortie
													seront nuls.

Exemple d’appel		:	SELECT * FROM [dbo].[fntGENE_ObtenirCedulesJob]('joIQEE_CreerFichiers')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iID_Cedule						
						S/O							vcNom_Cedule					
						S/O							dtDate_Execution				

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-04-21		Éric Deshaies						Création du service
		2010-04-12		Éric Deshaies						Correction d'un bug parce que le champ Active_Start_Time
															peut-être à 0.

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_ObtenirCedulesJob]
(
	@vcNom_Job VARCHAR(128)
)
RETURNS @tblGENE_CedulesJob TABLE
(
	iID_Cedule INT NOT NULL,
	vcNom_Cedule VARCHAR(128) NULL,
	dtDate_Execution DATETIME
)
AS
BEGIN
	-- Rechercher les informations sur les cédules
	INSERT INTO @tblGENE_CedulesJob
	SELECT V3.Schedule_ID,V3.Name,
		   CAST(SUBSTRING(CAST(V3.Active_Start_Date AS VARCHAR(8)),1,4)+'-'+
				SUBSTRING(CAST(V3.Active_Start_Date AS VARCHAR(8)),5,2)+'-'+
				SUBSTRING(CAST(V3.Active_Start_Date AS VARCHAR(8)),7,2)+' '+
				CASE WHEN V3.Active_Start_Time IS NULL OR V3.Active_Start_Time = 0 THEN '00:00:00'
					 ELSE SUBSTRING('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)),LEN('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)))-5,2)+':'+
						  SUBSTRING('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)),LEN('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)))-3,2)+':'+
						  SUBSTRING('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)),LEN('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)))-1,2)
				END
				AS DATETIME)
	FROM msdb.dbo.sysjobs_view V1
		 JOIN msdb.dbo.sysjobschedules V2 on V2.Job_ID = V1.Job_ID
		 JOIN msdb.dbo.sysschedules_localserver_view V3 ON V3.Schedule_ID = v2.Schedule_ID
													   AND V3.Enabled = 1
	WHERE V1.Name = @vcNom_Job
	  AND CAST(SUBSTRING(CAST(V3.Active_Start_Date AS VARCHAR(8)),1,4)+'-'+
				SUBSTRING(CAST(V3.Active_Start_Date AS VARCHAR(8)),5,2)+'-'+
				SUBSTRING(CAST(V3.Active_Start_Date AS VARCHAR(8)),7,2)+' '+
				CASE WHEN V3.Active_Start_Time IS NULL OR V3.Active_Start_Time = 0 THEN '00:00:00'
					 ELSE SUBSTRING('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)),LEN('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)))-5,2)+':'+
						  SUBSTRING('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)),LEN('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)))-3,2)+':'+
						  SUBSTRING('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)),LEN('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)))-1,2)
				END
				AS DATETIME) > GETDATE()
	ORDER BY CAST(SUBSTRING(CAST(V3.Active_Start_Date AS VARCHAR(8)),1,4)+'-'+
				SUBSTRING(CAST(V3.Active_Start_Date AS VARCHAR(8)),5,2)+'-'+
				SUBSTRING(CAST(V3.Active_Start_Date AS VARCHAR(8)),7,2)+' '+
				CASE WHEN V3.Active_Start_Time IS NULL OR V3.Active_Start_Time = 0 THEN '00:00:00'
					 ELSE SUBSTRING('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)),LEN('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)))-5,2)+':'+
						  SUBSTRING('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)),LEN('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)))-3,2)+':'+
						  SUBSTRING('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)),LEN('00'+CAST(V3.Active_Start_Time AS VARCHAR(6)))-1,2)
				END
				AS DATETIME)

	-- Retourner les informations
	RETURN 
END
