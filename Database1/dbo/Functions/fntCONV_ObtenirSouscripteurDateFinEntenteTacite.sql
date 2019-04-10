/***********************************************************************************************************************
Code de service     : fntCONV_ObtenirSouscripteurDateFinEntenteTacite
But                 : Retourne les souscripteur et la date de fin du lien d'affaire

Parametres d'entrée : 
        Parametres              Obligatoire     Description                             
        ----------              -----------     -----------------------------------------------
        @iID_Souscripteur       Non             Identifiant unique du souscripteur

Parametres de sortie :
        Champs                  Type        Description
        ------------------                  --------------------------
        SubscriberID            int         ID du soucripteur
        dtFinEntenteTacite      date        Date de fin de l'entente tacite

Exemple d'appel:
        SELECT * from  dbo.[fntCONV_ObtenirSouscripteurDateFinEntenteTacite] (NULL)
        SELECT * from  dbo.[fntCONV_ObtenirSouscripteurDateFinEntenteTacite] (485308)

Historique des modifications :
            
        Date            Programmeur                             Description
        ----------      ------------------------------------    -------------------------------------------
        2016-06-03      Patrice Côté                            Création de la fonction     
        2016-07-27      Steeve Picard                           Modification pour tenir compte de la date de fermeture des conventions      
        2016-08-01      Steeve Picard                           Retourner la date tacite '9999-12-31' lorsqu'il y a au moins une convention en REE ou TRA
 **********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirSouscripteurDateFinEntenteTacite] 
(
    @iID_Souscripteur        INT = NULL
)
RETURNS TABLE
AS RETURN
(
    WITH CTE_AvecLienAffaire as 
    (
        SELECT DISTINCT 
             C.SubscriberID,
             dtFinEntente = CASE S.ConventionStateID 
                                 WHEN 'FRM' THEN DateAdd(year, 2, S.StartDate)
                                 ELSE Cast('9999-12-31' as Date)
                            END
        FROM
            dbo.Un_Convention C
            JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) S ON S.conventionID = C.ConventionID
        WHERE
            C.SubscriberID = IsNull(@iID_Souscripteur, C.SubscriberID)
            AND S.ConventionStateID <> 'PRP'
    )
    SELECT DISTINCT
        SubscriberID, 
        dtFinEntenteTacite = Max(dtFinEntente)
    FROM
        CTE_AvecLienAffaire
    GROUP BY 
        SubscriberID
)
