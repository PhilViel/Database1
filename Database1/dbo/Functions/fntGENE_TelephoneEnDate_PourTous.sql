/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : fntGENE_TelephoneEnDate_PourTous
Nom du service	 : Déterminer le téléphone à une date
But 			 : Retourner le téléphone de tous à une date donnée.
Facette		 : GENE

Paramètres d’entrée	:   
    Paramètre				  Description
    ------------------------    -----------------------------------------------------------------
    dtDate_Debut			  Date pour laquelle le téléphone doit être déterminé. Si la date n’est pas fournie, on considère que c’est pour obtenir le téléphone le plus récent.
    iID_Source				  Identifiant de l’humain ou de l'entreprise
    iID_Type				  Type de téléphone désiré

Exemple d’appel : 
    SELECT * from dbo.fntGENE_TelephoneEnDate_PourTous (DEFAULT, DEFAULT, 4, 0, DEFAULT)
    SELECT * from dbo.fntGENE_TelephoneEnDate_PourTous (DEFAULT, 10019, DEFAULT, DEFAULT, 1)
    SELECT * from dbo.fntGENE_TelephoneEnDate_PourTous (DEFAULT, 155282, DEFAULT, DEFAULT, DEFAULT) where bInvalide <> 0
    SELECT * from dbo.fntGENE_TelephoneEnDate_PourTous (DEFAULT, 155282, DEFAULT, 1, DEFAULT)

Paramètres de sortie:	
    Table					  Champ					Description
    ------------------------    ------------------------    ---------------------------------
    tblGENE_Courriel		  vcCourriel				Courriel à la date demandée et pour le type demandé.  

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    ---------------------------------------------------------------------
    2016-05-20  Steeve Picard           Création du service
    2016-08-17  Steeve Picard           Optimisation en Inline Function
    2017-08-03  Steeve Picard           Ajout du champ «cType_Source» au résultat
                                        Ne pas ajouter l'extension si invalide
    2017-11-22  Steeve Picard           Filtrer selon l'ordre de l'index
    2018-02-27  Steeve Picard           Ajout du «cType_Source» dans le partitionnage du «Row_Number»
***************************************************************************************************************/
CREATE FUNCTION dbo.fntGENE_TelephoneEnDate_PourTous
(
    @dtDate_Debut           DATETIME = NULL,
    @iID_Source             INT      = NULL,
    @iID_Type               INT      = NULL,
    @afficherInvalide       BIT      = 0,
    @AjouterEspaceExtension BIT      = NULL
)
RETURNS TABLE
AS RETURN
    WITH CTE_Telephone AS (
        SELECT 
            iID_Source, cType_Source, iID_Type, vcTelephone, vcExtension,
            dtDate_Debut, bInvalide,
            Row_Num = ROW_NUMBER() OVER(PARTITION BY iID_Source, cType_Source, iID_Type ORDER BY dtDate_Debut DESC)
        FROM
            dbo.tblGENE_Telephone
        WHERE 
            iID_Source = IsNull(@iID_Source, iID_Source)
            AND iID_Type = IsNull(@iID_Type, iID_Type)
            AND IsNull(@dtDate_Debut, GetDate()) Between dtDate_Debut And DateAdd(DAY, -1, IsNull(dtDate_Fin, '9999-12-31'))
            --AND (bInvalide = 0 OR IsNull(@afficherInvalide, 0) <> 0)
    )
    SELECT 
        iID_Source, cType_Source, iID_Type, 
        vcTelephone = RTRIM(CASE WHEN bInvalide = 1 AND IsNull(@afficherInvalide, 0) <> 0 THEN '*** Invalide *** '
                                 ELSE vcTelephone + CASE WHEN ISNULL(@AjouterEspaceExtension, 0) = 1 THEN ' ' ELSE '' END + ISNULL(vcExtension, '')
                            END),
        dtDate_Debut, bInvalide
    FROM 
        CTE_Telephone
    WHERE
        Row_Num = 1
