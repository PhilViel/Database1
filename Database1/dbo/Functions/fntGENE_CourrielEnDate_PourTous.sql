/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : fnGENE_CourrielEnDate_Pourtous
Nom du service	 : Déterminer le courriel à une date
But 			 : Retourner le courriel de tous à une date donnée.
Facette		 : GENE
Référence		 : UniAccès-Noyau-GENE

Paramètres d’entrée	:   
    Paramètre				  Description
    ------------------------    -----------------------------------------------------------------
    iID_Source				  Identifiant de l’humain ou de l'entreprise
    iID_Type				  Type de courriel désiré
    dtDate_Debut			  Date pour laquelle le courriel doit être déterminé. Si la date n’est pas fournie, on considère que c’est pour obtenir le courriel le plus récent.

Exemple d’appel : 
    SELECT * from dbo.fntGENE_CourrielEnDate_PourTous (DEFAULT, DEFAULT, 0, DEFAULT)
    SELECT * from dbo.fntGENE_CourrielEnDate_PourTous (DEFAULT, DEFAULT, 1, DEFAULT)
    SELECT * from dbo.fntGENE_CourrielEnDate_PourTous (DEFAULT, 601864, DEFAULT, DEFAULT)
    select * from tblGENE_Courriel where iID_Source = 601864

Paramètres de sortie:	
    Table					  Champ					Description
    ------------------------    ------------------------    ---------------------------------
    tblGENE_Courriel		  vcCourriel				Courriel à la date demandée et pour le type demandé.  

Historique des modifications:
    Date		 Programmeur		   Description
    ----------  --------------------  ---------------------------------------------------------------------
    2016-05-20  Steeve Picard         Création du service
    2016-08-17  Steeve Picard         Optimisation en Inline Function
    2016-09-01  Steeve Picard         Ajout d'un paramètre optionel «iID_Source»
    2017-08-03  Steeve Picard         Ajout du champ «iID_Type» au résultat
    2018-02-27  Steeve Picard         Ajout du «cType_Source» dans le partitionnage du «Row_Number»
*********************************************************************************************************************/
CREATE FUNCTION dbo.fntGENE_CourrielEnDate_PourTous
(
	@dtDate_Debut DATE = NULL,
     @iID_Source int = NULL,
     @iID_TypeCourriel int = NULL,
	@afficherInvalide bit = NULL
)
RETURNS TABLE
AS RETURN
    WITH CTE_Courriel AS (
        SELECT 
            iID_Source, cType_Source, vcCourriel, iID_Type, dtDate_Debut, bInvalide,
            Row_Num = ROW_NUMBER() OVER(PARTITION BY iID_Source, cType_Source, iID_Type ORDER BY dtDate_Debut DESC)
        FROM
            dbo.tblGENE_Courriel
        WHERE 
            iID_Source = IsNull(@iID_Source, iID_Source)
            AND IsNull(@dtDate_Debut, GetDate()) Between dtDate_Debut And DateAdd(DAY, -1, IsNull(dtDate_Fin, '9999-12-31'))
            AND iID_Type = IsNull(@iID_TypeCourriel, iID_Type)
            --AND (bInvalide = 0 OR IsNull(@afficherInvalide, 0) <> 0)
    )
    SELECT iID_Source, cType_Source, 
           vcCourriel = CASE WHEN bInvalide = 1 AND IsNull(@afficherInvalide, 0) <> 0 THEN '*** Invalide *** ' ELSE vcCourriel END, 
           iID_Type, dtDate_Debut, bInvalide
      FROM CTE_Courriel
     WHERE Row_Num = 1
