/****************************************************************************************************
Code de service : fntCONV_ObtenirConventionParBeneficiaireEnDate
Nom du service  : Obtient la liste des convention d'un bénéficiaire à une date donnée
But             : Obtient la liste des convention d'un bénéficiaire à une date donnée
Facette         : CONV

Parametres d'entrée :    
    Parametres          Description
    ----------------    ----------------
    iID_Convention      ID de la convention concernée par l'appel
    Annee_Fiscale       Année fiscale considérée par l'appel

Exemple d'appel:
    SELECT * FROM DBO.fntIQEE_ObtenirMontantRecu_ParConvention (186900, NULL, NULL)

Parametres de sortie : Le solde SCEE

Historique des modifications :
    Date        Programmeur             Description
    ----------    ------------------    -------------------------------------------
    2016-03-21  Steeve Picard           Création de la fonction
    2016-04-08  Steeve Picard           Ajout de champs résultants
    2017-04-12  Steeve Picard           Ajout du champs résultant «iID_Convention»
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirConventionParBeneficiaireEnDate] (
	@dtDateFin date = NULL,
	@iID_Beneficiaire int = NULL
)
RETURNS TABLE
AS RETURN
(
	SELECT C.ConventionID, C.ConventionNo, 
            BeneficiaryID = CB.iID_Nouveau_Beneficiaire,
            dtDateDebut = dtDate_Changement_Beneficiaire
	  FROM (	SELECT iID_Convention, iID_Nouveau_Beneficiaire, dtDate_Changement_Beneficiaire,
					   Row_Num = Row_Number() OVER (PARTITION BY iID_Convention ORDER BY dtDate_Changement_Beneficiaire DESC)
				  FROM dbo.tblCONV_ChangementsBeneficiaire CB
				 WHERE dtDate_Changement_Beneficiaire <= IsNull(@dtDateFin, GetDate())
				   AND iID_Nouveau_Beneficiaire = IsNull(@iID_Beneficiaire, iID_Nouveau_Beneficiaire)
			) CB
			JOIN dbo.Un_Convention C ON C.ConventionID = CB.iID_Convention
	 WHERE CB.Row_Num = 1
)