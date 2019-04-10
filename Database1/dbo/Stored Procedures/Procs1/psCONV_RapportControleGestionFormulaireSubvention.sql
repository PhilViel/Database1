/****************************************************************************************************
Copyrights (c) 2015 Gestion Universitas inc.

Code du service		: psCONV_RapportControleGestionFormulaireSubvention
Nom du service		: Rapport de contrôle de la gestion des formulaires de subvention
But 				: Contrôler de la gestion des formulaires de subvention
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@DateDe						
						@DateA						

	
Exemple d'appel : 

EXECUTE psCONV_RapportControleGestionFormulaireSubvention @DateDe = '2015-07-03', @DateA = '2015-07-31'
drop proc psCONV_RapportControleGestionFormulaireSubvention

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2015-08-06		Donald Huppé				Création du service				glpi 15189
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportControleGestionFormulaireSubvention]
    (
	@DateDe Datetime,
	@DateA Datetime
    )
AS 
    BEGIN



	--set @DateDe = '2015-07-03'
	--set @DateA = '2015-07-31'


	SELECT 
		--C.ConventionID, 
		C.ConventionNo, 
		CSS.ConventionStateID,
		C.SCEEFormulaire93Recu,
		C.SCEEAnnexeBTuteurRequise,
		C.SCEEAnnexeBTuteurRecue,
		C.BeneficiaryID,
		BenNom = HB.LastName,
		BenPrenom = HB.FirstName,
		C.SubscriberID,
		SouscNom = HS.LastName,
		SouscPrenom = HS.FirstName,
		B.iTutorID,
		TuteurNom = HT.LastName,
		TuteurPrenom = HT.FirstName
	FROM dbo.Un_Convention C
	JOIN (
		SELECT 
			U.ConventionID,
			MinUnit = MIN(U.UnitID)
		FROM dbo.Un_Unit U 
		GROUP BY U.ConventionID
		) UMin ON UMin.ConventionID = C.ConventionID
	JOIN dbo.Un_Unit U ON U.UnitID = UMin.MinUnit
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID 
	JOIN dbo.Mo_Human HT ON HT.HumanID = B.iTutorID 
	JOIN (
		SELECT 
			C.BeneficiaryID,
			NBConv = COUNT(C.ConventionID)
		FROM dbo.Un_Convention C
		GROUP BY C.BeneficiaryID
		) CB ON CB. BeneficiaryID = C.BeneficiaryID
	LEFT JOIN (
			SELECT
				CS.ConventionID ,
				CCS.StartDate ,
				CS.ConventionStateID
			FROM dbo.Un_ConventionConventionState CS
			JOIN (
				SELECT
					ConventionID ,
					StartDate = MAX(StartDate)
				FROM dbo.Un_ConventionConventionState
				--WHERE StartDate < DATEADD(d, 1, GETDATE())
				GROUP BY ConventionID
				 ) CCS ON CCS.ConventionID = CS.ConventionID
					AND CCS.StartDate = CS.StartDate 
			) CSS on C.ConventionID = CSS.ConventionID
	WHERE
		c.ConventionNo like '%-%'

		AND cast(SUBSTRING(c.ConventionNo,3,4) + '-' + SUBSTRING(c.ConventionNo,7,2) + '-' + SUBSTRING(c.ConventionNo,9,2) as date) BETWEEN @DateDe and @DateA

		AND (
			 CSS.ConventionStateID not in ( 'FRM', 'PRP')
			AND (
					ISNULL(C.SCEEFormulaire93Recu, 0) = 0
					OR
					(	ISNULL(C.SCEEAnnexeBTuteurRequise, 0) = 1
						AND ISNULL(C.SCEEAnnexeBTuteurRecue, 0) = 0
					)
				)
			)
	ORDER BY
		HS.LastName,
		HS.FirstName

END
