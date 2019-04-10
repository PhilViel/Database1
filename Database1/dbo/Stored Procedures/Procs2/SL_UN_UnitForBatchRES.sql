/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_UnitForBatchRES
Description         :	Procédure retournant les données pour remplir la grille de visualisation de l’outil de 
						résiliation par lot.  Elle doit être appelée à l’ouverture de l’outil et après les recherches 
						de conventions à ajouter.

Valeurs de retours  :	Dataset :
									UnitID						ID unique du groupe d'unités
									ConventionID				ID unique de la convention.
									ConventionNo				Numéro de la convention.
									Subscriber					Souscripteur de la convention.
									RESType						EPG = Épg. (Seulement les épargnes seront remboursées au 
																souscripteur.  Les frais seront transférés (TFR) dans les frais 
																disponibles de la convention pour les conventions collectives et 
																dans les frais éliminés pour les conventions individuelles.)
																FEE = Épg., frais et ass. (Les épargnes, les frais, les primes 
																d’assurance souscripteur et d’assurance bénéficiaire ainsi que les 
																taxes seront remboursés au souscripteur.)
									UnitReductionReasonID		Raison de la résiliation, par défaut vide. 
									HoldPaymentDate				Date d’arrêt de paiement. 
									BreakingTypeID				Type d’arrêt de paiement.
									UnitQty						Unités : Total des unités de la convention avant la résiliation.
									IntINC						Intérêts client.
									Cotisation					Épargnes.
									Fee							Frais.
									SubscInsur					Assurance souscripteur.
									BenefInsur					Assurance bénéficiaire.
									TaxOnInsur					Taxes.
									bIsContestWinner			Indique si la source de vente du groupe d'unités est de type gagnant de concours

Note                :			ADX0000693	IA	2005-05-17	Bruno Lapointe		        Création
								ADX0001750	BR	2005-11-15	Bruno Lapointe		        Le type de résiliation "Epg." et "Epg, frais et ass."
																				        étaient inversés.
								ADX0001357	IA	2007-06-04	Alain Quirion		        Ajout du champ bIsContestWinner
												2011-04-01	Frédérick Thibault	        Ajout du type d'arrêt de paiement 'TRI' (FT1)
												2015-10-01	Steeve Picard		        Utilisation de la valeur par défaut du nouveau paramètre de «fnCONV_ObtenirDateDebutRegime»
                                                2017-03-20  Philippe Dubé-Tremblay      Ajout d'une condition pour éviter une résiliation d'une convention faisant l'objet d'une marge.
                                                2018-02-13  Pierre-Luc Simard           Exclure aussi les RIN partiel
                                                2018-12-05  Pierre-Luc Simard           Valider la présence d'un RIN avec la fonction fntCONV_ObtenirUniteAvecRIN au lieu de la fntCONV_ObtenirStatutRINUnite
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_UnitForBatchRES] (
	@BlobID INTEGER,		-- ID du blob qui contient les ID des conventions séparés par des ;
	@GiveRESBreaking BIT )	-- True, va retourner toutes les groupes d'unités des conventions avec un arrêt de paiement 
							-- avec raison 'Résiliation' ou 'Résiliation sans NAS' en plus des groupes d'unités des 
							-- conventions qui sont énumérés dans le blob.
AS
BEGIN
	CREATE TABLE #ConventionToRES (
		ConventionID INTEGER PRIMARY KEY)

	INSERT INTO #ConventionToRES
		SELECT
			ConventionID = Val
		FROM dbo.FN_CRQ_BlobToIntegerTable(@BlobID)
		-----
		UNION
		-----
		SELECT
			ConventionID
		FROM Un_Breaking
		WHERE @GiveRESBreaking = 1
			AND GETDATE() BETWEEN BreakingStartDate AND ISNULL(BreakingEndDate,GETDATE()+1)
			AND BreakingTypeID IN ('RES','RNA','TRI')

	SELECT DISTINCT
		U.UnitID, -- ID unique du groupe d'unités
		C.ConventionID, -- ID unique de la convention.
		C.ConventionNo, -- Numéro de la convention.
		C.SubscriberID, -- ID du souscripteur
		Subscriber = S.LastName+', '+S.FirstName, -- Souscripteur de la convention.
		RESType = 
			CASE 
				WHEN DATEDIFF(MONTH, U.InForceDate, GETDATE()) < 2 
					OR ( DATEDIFF(MONTH, U.InForceDate, GETDATE()) = 2
						AND DAY(U.InForceDate) >= DAY(GETDATE())
						) THEN 'FEE'
			ELSE 'EPG'
			END, -- EPG = Épg. (Seulement les épargnes seront remboursées au souscripteur.  Les frais seront transférés (TFR) dans les frais disponibles de la convention pour les conventions collectives et dans les frais éliminés pour les conventions individuelles.) FEE = Épg., frais et ass. (Les épargnes, les frais, les primes d’assurance souscripteur et d’assurance bénéficiaire ainsi que les taxes seront remboursés au souscripteur.)
		UnitReductionReasonID = 0, -- Raison de la résiliation, par défaut vide. 
		HoldPaymentDate = ISNULL(B.BreakingStartDate,UHP.StartDate), -- Date d’arrêt de paiement. 
		BreakingTypeID = ISNULL(B.BreakingTypeID,''), -- Type d’arrêt de paiement.
		UnitQty = U.UnitQty, -- Unités : Total des unités de la convention avant la résiliation.
		IntINC = 0, -- Intérêt client
		Cotisation = ISNULL(Ct.Cotisation,0), -- Épargnes.
		Fee = ISNULL(Ct.Fee,0), -- Frais.
		SubscInsur = ISNULL(Ct.SubscInsur,0), -- Assurance souscripteur.
		BenefInsur = ISNULL(Ct.BenefInsur,0), -- Assurance bénéficiaire.
		TaxOnInsur = ISNULL(Ct.TaxOnInsur,0), -- Taxes.
		bIsContestWinner = ISNULL(SS.bIsContestWinner,0)
		
		-- FT1
		--,dtRegStartDate = C.dtRegStartDate
		,dtRegStartDate = dbo.fnCONV_ObtenirDateDebutRegime(C.ConventionID, NULL)  -- 2015-10-01
		,PlanType =
			CASE 
				WHEN P.PlanID = 4 THEN
					'IND'
				WHEN P.PlanID = 8 THEN
					'UNI'
				WHEN P.PlanID = 10 THEN
					'REE'
				WHEN P.PlanID = 11 THEN
					'UNI'
				WHEN P.PlanID = 12 THEN
					'REE'
			END
		
	FROM #ConventionToRES CRES
	JOIN dbo.Un_Convention C ON C.ConventionID = CRES.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
    --LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, GETDATE()) RIN ON RIN.UnitID = U.UnitID
    LEFT JOIN dbo.fntCONV_ObtenirUniteAvecRIN(NULL, NULL, GETDATE()) RIN ON RIN.UnitID = U.UnitID
	LEFT JOIN (
		SELECT
			BC.ConventionID,
			BreakingID = MAX(B.BreakingID)
		FROM (
			SELECT
				CRES.ConventionID,
				BreakingStartDate = MAX(B.BreakingStartDate)
			FROM #ConventionToRES CRES
			JOIN Un_Breaking B ON B.ConventionID = CRES.ConventionID
			WHERE GETDATE() BETWEEN B.BreakingStartDate AND ISNULL(B.BreakingEndDate,GETDATE()+1)
			GROUP BY CRES.ConventionID
			) BC 
		JOIN Un_Breaking B ON B.ConventionID = BC.ConventionID AND B.BreakingStartDate = BC.BreakingStartDate
		WHERE GETDATE() BETWEEN B.BreakingStartDate AND ISNULL(B.BreakingEndDate,GETDATE()+1)
		GROUP BY BC.ConventionID
		) BC ON BC.ConventionID = C.ConventionID
	LEFT JOIN Un_Breaking B ON B.BreakingID = BC.BreakingID
	LEFT JOIN (
		SELECT
			UUHP.UnitID,
			UnitHoldPaymentID = MAX(UHP.UnitHoldPaymentID)
		FROM (
			SELECT
				U.UnitID,
				StartDate = MAX(UHP.StartDate)
			FROM #ConventionToRES CRES
			JOIN dbo.Un_Unit U ON U.ConventionID = CRES.ConventionID
			JOIN Un_UnitHoldPayment UHP ON UHP.UnitID = U.UnitID
			WHERE GETDATE() BETWEEN UHP.StartDate AND ISNULL(UHP.EndDate,GETDATE()+1)
			GROUP BY U.UnitID
			) UUHP 
		JOIN Un_UnitHoldPayment UHP ON UHP.UnitID = UUHP.UnitID AND UHP.StartDate = UUHP.StartDate
		WHERE GETDATE() BETWEEN UHP.StartDate AND ISNULL(UHP.EndDate,GETDATE()+1)
		GROUP BY UUHP.UnitID
		) UUHP ON UUHP.UnitID = U.UnitID
	LEFT JOIN Un_UnitHoldPayment UHP ON UHP.UnitHoldPaymentID = UUHP.UnitHoldPaymentID
	LEFT JOIN (
		SELECT
			U.UnitID,
			Cotisation = SUM(Ct.Cotisation),
			Fee = SUM(Ct.Fee),
			SubscInsur = SUM(Ct.SubscInsur),
			BenefInsur = SUM(Ct.BenefInsur),
			TaxOnInsur = SUM(Ct.TaxOnInsur)
		FROM #ConventionToRES CRES
		JOIN dbo.Un_Unit U ON U.ConventionID = CRES.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		GROUP BY U.UnitID
		) Ct ON Ct.UnitID = U.UnitID
	LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
	WHERE U.TerminatedDate IS NULL
		--AND U.IntReimbDate IS NULL
        --AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
        AND RIN.UnitID IS NULL -- Exclure les groupes d'unités avec un RIN partiel ou complet
        AND C.tiMaximisationREEE <> 2

	DROP TABLE #ConventionToRES
END
