/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: fntCONV_PremierChangementSouscripteur
Nom du service		: Déterminer le 1er changement de souscripteur à partir d'une date donnée
But 				: Déterminer s'il y a eu des changements de souscripteur pour une ou des convention(s) depuis une date donnée
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@p_dtAfterDate				Date à partir de laquelle on vérifie les changement de souscripteur.  
                                                    Si la date n’est pas fournie, on considère que c’est pour la date du jour.
		  				@p_iConventionID    		Identifiant de la convention pour laquelle on détermine s'il y a eu changement.
                                                    Si le ID de la convention n'est pas fourni, on les retourne tous

Exemple d’appel		:	select * FROM dbo.fntCONV_PremierChangementSouscripteur( DEFAULT, DEFAULT)

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
		2017-06-07		Steeve Picard						Création du service							
		2017-08-07		Steeve Picard						Amélioration dans le cas où le «SubscriberID» n'est pas sur la 1ère ligne
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_PremierChangementSouscripteur](
    @p_dtAfterDate DATE,
    @p_iConventionID INT = NULL
)
RETURNS TABLE
AS RETURN
(
    WITH CTE_LogLine AS (
            SELECT 
                LogCodeID, LogDesc, LogTime, LoginName,
                LogData = Substring(Cast(LogText as varchar(max)), CharIndex('SubscriberID' + char(30), LogText), 8000)
            FROM 
                dbo.CRQ_Log
            where 0=0 --LogCodeID = 172048
                and logtablename = 'un_Convention'
                and LogCodeID = IsNull(@p_iConventionID, LogCodeID)
                and Cast(logTime as date) > IsNull(@p_dtAfterDate, GetDate())
                and LogActionID = 2
                and Replace(CAST(LogText AS varchar(MAX)), 'CoSubscriberID', 'CoSubID') Like '%SubscriberID%'
                --and not LogText Like '%CoSubscriberID%'
         ), 
         CTE_Log as (
            SELECT 
                LogCodeID, LogDesc, LogTime, LoginName,
                LogData = Replace(Left(LogData, CharIndex(char(13), LogData) - 2), 'SubscriberID' + char(30), ''),
                Row_Num = Row_Number() OVER(Partition By LogCodeID Order By LogTime)
            FROM 
                CTE_LogLine
         ),
         CTE_Old as (
            SELECT
                LogCodeID, LogDesc, LogTime, LoginName,
                ID_Old = Left(LogData, CharIndex(Char(30), LogData) -1),
                LogData = SubString(LogData, CharIndex(Char(30), LogData) + 1, Len(LogData))
            FROM
                CTE_Log
            WHERE
                Row_Num = 1
         ),
         CTE_New as (
            SELECT
                ConventionID = LogCodeID, 
                ConventionNo = Replace(LogDesc, 'Convention : ', ''), 
                dtChangement = Cast(LogTime as date), 
                SubscriberID_Old = Cast(ID_Old as int),
                SubscriberID_New = Cast(Left(LogData, CharIndex(Char(30), LogData) -1) as int),
                Subscriber_Names = Replace(SubString(LogData, CharIndex(Char(30), LogData) + 1, Len(LogData)), Char(30) , ' -> '),
                LoginName
            FROM
                CTE_Old
         )
    SELECT
        *
    FROM
        CTE_New
)
