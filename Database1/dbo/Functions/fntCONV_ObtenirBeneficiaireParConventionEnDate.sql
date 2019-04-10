CREATE FUNCTION [dbo].[fntCONV_ObtenirBeneficiaireParConventionEnDate] (
	@dtDateFin date = NULL,
	@iID_Convention int = NULL
)
RETURNS TABLE
AS RETURN
(
	SELECT iID_Convention, CB.iID_Nouveau_Beneficiaire as iID_Beneficiaire, 
	                       H.LastName as Nom, H.FirstName as Prenom, 
						   Cast(H.Birthdate as Date) as DateNaissance, H.SexID as Sexe, H.SocialNumber as NAS,
						   dtDate_Changement_Beneficiaire as dtDateDebut
	  FROM (	SELECT iID_Convention, iID_Nouveau_Beneficiaire, dtDate_Changement_Beneficiaire,
					   Row_Num = Row_Number() OVER (PARTITION BY iID_Convention ORDER BY dtDate_Changement_Beneficiaire DESC)
				  FROM dbo.tblCONV_ChangementsBeneficiaire CB
				 WHERE dtDate_Changement_Beneficiaire <= IsNull(@dtDateFin, GetDate())
				   AND iID_Convention = IsNull(@iID_Convention, iID_Convention)
			) CB
			JOIN dbo.Mo_Human H ON H.HumanID = CB.iID_Nouveau_Beneficiaire
	 WHERE CB.Row_Num = 1
)
