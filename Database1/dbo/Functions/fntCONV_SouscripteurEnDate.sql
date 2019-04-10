/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: fntCONV_SouscripteurEnDate
Nom du service		: Déterminer le souscripteur actif des conventions à une date donnée
But 				: Déterminer le souscripteur d’une ou des convention(s) à une date donnée
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@p_dtEnDate					Date pour laquelle les souscripteurs doivent être déterminés.  
                                                    Si la date n’est pas fournie, on considère que c’est pour la date du jour.
		  				@p_iConventionID    		Identifiant de la convention pour laquelle on détermine le souscripteur.
                                                    Si le ID de la convention n'est pas fourni, on les retourne tous

Exemple d’appel		:	select * FROM dbo.fntCONV_SouscripteurEnDate( DEFAULT, DEFAULT)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iID_Souscripteur				Identifiant du souscripteur à la
																					date demandée.  La valeur de
																					retour 0 indique que le
																					souscripteur n’existe plus
																					dans la base de données.

Historique des modifications:
		Date			Programmeur							Description
		------------	----------------------------------	-----------------------------------------
		2017-08-07		Steeve Picard						Création du service							
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_SouscripteurEnDate](
    @p_dtEnDate date = NULL,
    @p_iConventionID INT = NULL
)
RETURNS TABLE
AS RETURN
(
    WITH CTE_LogLine AS (
            SELECT 
                LogCodeID, LogDesc, LogActionID, LogTime, LoginName,
                LogData = Substring(Cast(LogText as varchar(max)), CharIndex('SubscriberID' + char(30), LogText), 8000)
            FROM 
                dbo.CRQ_Log
            where 0=0 --LogCodeID = 172048
                and logtablename = 'un_Convention'
                and LogCodeID = IsNull(@p_iConventionID, LogCodeID)
                and Cast(logTime as date) < IsNull(@p_dtEnDate, GetDate())
                and LogActionID IN (1, 2)
                and Replace(CAST(LogText AS varchar(MAX)), 'CoSubscriberID', 'CoSubID') Like '%SubscriberID%'
                --and not LogText Like '%CoSubscriberID%'
         ), 
         CTE_Log as (
            SELECT 
                LogCodeID, LogDesc, LogActionID, LogTime, LoginName,
                LogData = Replace(Left(LogData, CharIndex(char(13), LogData) - 2), 'SubscriberID' + char(30), ''),
                Row_Num = Row_Number() OVER(Partition By LogCodeID Order By LogTime DESC)
            FROM 
                CTE_LogLine
         ),
         CTE_Old as (
            SELECT
                LogCodeID, LogDesc, LogTime, LoginName,
                ID_Old = CASE LogActionID WHEN 1 THEN NULL ELSE Left(LogData, CharIndex(Char(30), LogData) -1) END,
                LogData = CASE LogActionID WHEN 1 THEN logData ELSE Substring(LogData, CharIndex(Char(30), LogData) + 1, Len(LogData)) END
            FROM
                CTE_Log
            WHERE
                Row_Num = 1
         ),
         CTE_New as (
            SELECT
                C.ConventionID, C.ConventionNo, 
                dtChangement = Cast(IsNull(L.LogTime, C.dtSignature) as date), 
                SubscriberID_Old = Cast(L.ID_Old as int),
                SubscriberID_New = CASE WHEN L.LogData IS NULL THEN C.SubscriberID ELSE Cast(Left(L.LogData, CharIndex(Char(30), L.LogData) -1) as int) END,
                Subscriber_Names = Replace(SubString(L.LogData, CharIndex(Char(30), L.LogData) + 1, Len(L.LogData)), Char(30) , ' -> '),
                LoginName = IsNull(L.LoginName, c.LoginName)
            FROM
                dbo.Un_Convention C
                LEFT JOIN CTE_Old L ON L.LogCodeID = C.ConventionID
            WHERE
                C.ConventionID = IsNull(@p_iConventionID, C.ConventionID)
         )
    SELECT
        *
    FROM
        CTE_New
)
