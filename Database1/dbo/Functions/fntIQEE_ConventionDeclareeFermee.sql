/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service :   fntIQEE_ConventionDeclareeFermee
Nom du service  :   Toutes conventions dont une déclaration de fermeture est en vigueur
But             :   Déterminer toutes les conventions qui ont été déclarées fermées à RQ.
Facette         :   IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    ---------------------------------------------------------------------------
    @iID_Fichier_IQEE       Identifiant de fichier à inclure.

Exemple d’appel :
    SELECT * from dbo.fntIQEE_ConventionDeclareeFermee(DEFAULT)

Paramètres de sortie :
    Champ                   Description
    --------------------    ---------------------------------
    iID_Convention          Identifiant de convention

Historique des modifications:
    Date        Programmeur         Description
    ----------  -----------------   -----------------------------------------------------
    2018-02-06  Steeve Picard       Création du service à partir de fnIQEE_ConventionConnueRQ
*********************************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_ConventionDeclareeFermee (
    @iID_Fichier_IQEE INT 
)
RETURNS TABLE
AS RETURN
(
    WITH CTE_Fichier AS (
        SELECT DISTINCT 
            iID_Fichier_IQEE
        FROM 
            dbo.tblIQEE_Fichiers F
            JOIN dbo.tblIQEE_TypesFichier T ON T.tiID_Type_Fichier = F.tiID_Type_Fichier
        WHERE
            0 = 0 --T.bTeleversable_RQ <> 0
            AND ( (bFichier_Test = 0 AND bInd_Simulation = 0)
                  OR iID_Fichier_IQEE = @iID_Fichier_IQEE
                )
    ),
    CTE_Impot AS (
        SELECT 
            I.iID_Convention, I.tiCode_Version, I.cStatut_Reponse,
            Row_Num = ROW_NUMBER() OVER(PARTITION BY I.iID_Convention ORDER BY i.iID_Impot_Special DESC)
        FROM 
            dbo.tblIQEE_ImpotsSpeciaux I
            JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.iID_Sous_Type = I.iID_Sous_Type
            JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
        WHERE
            T.cCode_Sous_Type IN ('51', '91')
            AND Not Exists (
                SELECT * FROM dbo.tblIQEE_Annulations A
                         JOIN dbo.tblIQEE_TypesEnregistrement T ON T.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                 WHERE T.cCode_Type_Enregistrement = '06'
                   AND A.iID_Enregistrement_Demande_Annulation = I.iID_Impot_Special
            )
    )
    SELECT 
        iID_Convention
    FROM
        CTE_Impot
    WHERE
        Row_Num = 1
        AND tiCode_Version IN (0, 2)
        AND cStatut_Reponse IN ('A', 'R')
)
