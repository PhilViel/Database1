/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas Inc.
Nom                 :	psREPR_ObtenirListeRepresentantEtDirecteur
Description         :	PROCEDURE DU RAPPORT DE LA LISTE DES REPRÉSENTANTS AVEC LEURS SUPÉRIEURS
Valeurs de retours  :	DATASET
Note                :	2010-01-21 	Donald Huppé	Création de la procédures stockée

exec psREPR_ObtenirListeRepresentantEtDirecteur 1

*******************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ObtenirListeRepresentantEtDirecteur] (

	@ConnectID	INTEGER)

AS
SELECT
	R.RepCode,
	RLastname = H.LastName,
	RFirstName = H.FirstName,
	R.BusinessStart,
	R.BusinessEnd,
	BLastname = HB.LastName,
	BFirstName = HB.FirstName,
	RepRole = RB.RepRoleID + '-' + RR.RepRoleDesc,
	RB.RepBossPct,
	RB.StartDate,
	RB.EndDate
FROM
	Un_Rep R
	JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	JOIN Un_RepBossHist RB ON RB.RepID = R.RepID
	JOIN UN_RepRole RR on RR.RepRoleID = RB.RepRoleID 
	JOIN dbo.Mo_Human HB ON HB.HumanID = RB.BossID
WHERE
	R.BusinessStart <= GETDATE() AND ISNULL(R.BusinessEnd,GETDATE()) >= GETDATE()
	AND RB.StartDate <= GETDATE() AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
ORDER BY 
	H.LastName,
	H.FirstName,
	HB.LastName,
	HB.FirstName
	

