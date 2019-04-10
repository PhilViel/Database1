/****************************************************************************************************
Code de service :   fntIQEE_CotisationsEtAyantEuDroit_ParConvention
Nom du service  :   Obtient le montant accumulé de cotisation et la portion ayant eu droit à l'IQEE par convention
But             :   Obtient le ayant eu droit à l'IQEE par convention
Facette         :   IQEE
Reférence       :   Système de gestion de la relation client

Parametres d'entrée :
    Parametres          Description
    ----------          ----------------
    iID_Convention      ID de la convention concernée par l'appel
    Annee_Fiscale       Année fiscale considérée par l'appel


Exemple d'appel:
    SELECT * FROM dbo.fntIQEE_CotisationsEtAyantEuDroit_ParConvention (374011, NULL, NULL)
    SELECT * FROM dbo.fntIQEE_CotisationsEtAyantEuDroit_ParConvention (NULL, 2015, NULL)

Parametres de sortie : 

Historique des modifications :
            
    Date        Programmeur                 Description
    ----------    ----------------------    ---------------------------------------------------------
    2016-03-21  Steeve Picard               Création de la fonction
    2016-04-08  Steeve Picard               Ajout de champs résultants
    2018-03-21  Steeve Picard               Renommer la fonction qui était «fntIQEE_ObtenirSoldeRQ_ParConvention» auparavant
 ****************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_CotisationsEtAyantEuDroit_ParConvention
(    
    @iID_Convention INT = NULL,
    @siAnneeFiscale INT = NULL,
    @dtEnDateDu DATE = NULL
)
RETURNS TABLE 
AS
RETURN 
(
    SELECT 
        iID_Convention, 
        siAnnee_Fiscale = Max(siAnnee_Fiscale), 
        dtDate_Traitement_RQ = Max(dtDate_Traitement_RQ), 
        Solde_Ayant_Droit_IQEE = Sum(Ayant_Droit_IQEE),
        Solde_Cotisation = Sum(Cotisation)
    FROM 
        dbo.fntIQEE_ObtenirMontantRecu_ParConvention(@iID_Convention, NULL, @dtEnDateDu)
    WHERE 
        siAnnee_Fiscale <= IsNull(@siAnneeFiscale, Year(GetDate()))
    GROUP BY 
        iID_Convention
)
