﻿/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_RapportIQEEParCompteSoucripteur
Nom du service		: Rapport d'IQEE Par Compte Souscripteur
But 				: Rapport d'IQEE Par Compte Souscripteur
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@dtDateDe					Date minimum d'opération
		  				@dtDateA					Date maximum d'opération	
		  				
Exemple d’appel		:	

EXECUTE dbo.psIQEE_RapportIQEEParCompteSoucripteur '2011-01-01','2011-02-28',NULL,NULL,10
EXECUTE dbo.psIQEE_RapportIQEEParCompteSoucripteur '2016-02-26','2016-02-26',NULL,NULL,0

select * from un_plan

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-04-20		Donald Huppé						Création du service							
		2011-01-12		Éric Deshaies						Correction de l'appel dans les commentaires de l'entête
		2011-02-24		Donald Huppé						GLPI 4422 : Ajout des 3 nouveaux critères de recherche : @cConventionno, @iYearQualif, @iPlanID
		2011-03-08		Donald Huppé						GLPi 5179 : Ajout des champs IQEE_InteretRecuRQ et IQEE_Rendement_ARI
		2011-03-18		Donald Huppé						Ajout des subventions TIO TIN et TIO OUT
		2011-03-25		Donald Huppé						GLPI 5285 : ajout de la colonne "IQEE, IQEE+ transf. (ARI)" (subvention ARI)
		2011-05-19		Donald Huppé						GLPI 5510 Ajout de TRI et RIM
		2012-09-14		Donald Huppé						Ajout de IQEE_FraisChargésRQ
		2016-05-12		Donald Huppé						JIRA TI-2317 : Ajout du PRA 
		2018-01-16		Donald Huppé						modification de la gestion des TIO.  voir table un_TIO au lieu de Cpny.companyname = 'Universitas'
        2018-11-08      Pierre-Luc Simard                   Utilisation du nom complet du plan
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_RapportIQEEParCompteSoucripteur] 
(
	@dtDateDe datetime,
	@dtDateA datetime,
	@cConventionno varchar(15) = NULL,
	@iYearQualif INT = NULL,
	@iPlanID varchar(75) = 0
)
AS
BEGIN

	SELECT 
		P.OrderOfPlanInReport,
		P.PlanID, -- ID unique du régime
        PlanDesc = P.NomPlan,
		YearQualif = ISNULL(Y.YearQualif,C.YearQualif), -- Année de qualification aux bourses de la convention. C'est l'année à laquelle le bénéficiaire de la convention pourra toucher sa première bourse pour cette convention s'il rempli les conditions.
		C.ConventionNo,
		vcSubscriber = HS.LastName+', '+HS.FirstName,
		--fUnitQty = SUM(UnitQty),
		IQEE_SubvBaseRecu = SUM(IQEE_SubvBaseRecu),
		IQEE_SubvMajorationRecu = SUM(IQEE_SubvMajorationRecu),
		IQEE_InteretRecuRQ = SUM(IQEE_InteretRecuRQ),
		IQEE_SubvTIN = SUM(IQEE_SubvTIN),
		IQEE_SubvOUT = SUM(IQEE_SubvOUT),
		IQEE_Rendement = SUM(IQEE_Rendement),
		IQEE_RendementTIN = SUM(IQEE_RendementTIN),
		IQEE_RendementOUT = SUM(IQEE_RendementOUT),
		IQEE_PAE = SUM(IQEE_Subv_PAE) + SUM(IQEE_Rendement_PAE),
		IQEE_PRA = SUM(IQEE_Rendement_PRA),
		IQEE_RIO = SUM(IQEE_Subv_RIO) + SUM(IQEE_Rendement_RIO),
		IQEE_TIO = SUM(IQEE_RendementTIOTIN) + SUM(IQEE_RendementTIOOUT) + SUM(IQEE_SubvTIOTIN) + SUM(IQEE_SubvTIOOUT),

		IQEE_TRI = SUM(IQEE_Subv_TRI) + SUM(IQEE_Rendement_TRI),
		IQEE_RIM = SUM(IQEE_Subv_RIM) + SUM(IQEE_Rendement_RIM),

		IQEE_Rendement_ARI = SUM(IQEE_Rendement_ARI),
		IQEE_Subv_ARI = SUM(IQEE_Subv_ARI),
		SoldeNetAll = 
			SUM(IQEE_SubvBaseRecu) + 
			SUM(IQEE_SubvMajorationRecu) + 
			SUM(IQEE_InteretRecuRQ) +
			SUM(IQEE_SubvTIN) + 
			SUM(IQEE_SubvOUT) + 
			SUM(IQEE_Rendement) + 
			SUM(IQEE_RendementTIN) +
			SUM(IQEE_RendementTIOTIN) +
			SUM(IQEE_SubvTIOTIN) +
			SUM(IQEE_RendementOUT) +
			SUM(IQEE_RendementTIOOUT) +
			SUM(IQEE_SubvTIOOUT) + 
			SUM(IQEE_Subv_PAE) +
			SUM(IQEE_Rendement_PAE) + 
			SUM(IQEE_Rendement_PRA) +
			SUM(IQEE_Subv_RIO) +
			SUM(IQEE_Rendement_RIO) + 
			SUM(IQEE_Subv_TRI) +
			SUM(IQEE_Rendement_TRI) + 
			SUM(IQEE_Subv_RIM) +
			SUM(IQEE_Rendement_RIM) + 
			SUM(IQEE_Rendement_ARI) + 
			SUM(IQEE_Subv_ARI),
		SoldeNetSubvention = 
			SUM(IQEE_SubvBaseRecu) + 
			SUM(IQEE_SubvMajorationRecu) + 
			SUM(IQEE_SubvTIN) + 
			SUM(IQEE_SubvOUT) + 
			SUM(IQEE_SubvTIOTIN) + 
			SUM(IQEE_SubvTIOOUT) +
			SUM(IQEE_Subv_PAE) +
			SUM(IQEE_Subv_RIO) +
			SUM(IQEE_Subv_TRI) +
			SUM(IQEE_Subv_RIM) +
			SUM(IQEE_Subv_ARI),
		SoldeNetRendement = 
			SUM(IQEE_InteretRecuRQ) + 
			SUM(IQEE_Rendement) + 
			SUM(IQEE_RendementTIN) +
			SUM(IQEE_RendementTIOTIN) +
			SUM(IQEE_RendementOUT) +
			SUM(IQEE_RendementTIOOUT) +
			SUM(IQEE_Rendement_PAE) + 
			SUM(IQEE_Rendement_PRA) +
			SUM(IQEE_Rendement_RIO) + 
			SUM(IQEE_Rendement_TRI) + 
			SUM(IQEE_Rendement_RIM) + 
			SUM(IQEE_Rendement_ARI),
		IQEE_FraisChargésRQ = SUM(IQEE_FraisChargésRQ)
	FROM (
		SELECT 
			CO.ConventionID,
			IQEE_SubvBaseRecu =			SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_BASE_CONVENTION'			THEN ConventionOperAmount ELSE 0 END),
			IQEE_SubvMajorationRecu =	SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_MAJORATION_CONVENTION'	THEN ConventionOperAmount ELSE 0 END),
			IQEE_InteretRecuRQ =		SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_InteretRecuDeRQ_CONVENTION'	THEN ConventionOperAmount ELSE 0 END),
			IQEE_SubvTIN = 0,
			IQEE_SubvTIOTIN = 0,
			IQEE_SubvOUT = 0,
			IQEE_SubvTIOOUT = 0,
			IQEE_Rendement =			SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_Universitas_CONVENTION' THEN ConventionOperAmount ELSE 0 END),
			IQEE_RendementTIN = 0,
			IQEE_RendementTIOTIN = 0,
			IQEE_RendementOUT = 0,
			IQEE_RendementTIOOUT = 0,
			IQEE_Subv_PAE =				SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_PAE_CONVENTION'			THEN ConventionOperAmount ELSE 0 END),
			IQEE_Rendement_PAE =		SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_PAE_CONVENTION'		THEN ConventionOperAmount ELSE 0 END),
			IQEE_Rendement_PRA =		SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_PRA_CONVENTION'		THEN ConventionOperAmount ELSE 0 END),
			IQEE_Subv_RIO =				SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_RIO_CONVENTION'			THEN ConventionOperAmount ELSE 0 END),
			IQEE_Rendement_RIO =		SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_RIO_CONVENTION'		THEN ConventionOperAmount ELSE 0 END),
			IQEE_Subv_TRI =				SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_TRI_CONVENTION'			THEN ConventionOperAmount ELSE 0 END),
			IQEE_Rendement_TRI =		SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_TRI_CONVENTION'		THEN ConventionOperAmount ELSE 0 END),
			IQEE_Subv_RIM =				SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_RIM_CONVENTION'			THEN ConventionOperAmount ELSE 0 END),
			IQEE_Rendement_RIM =		SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_RIM_CONVENTION'		THEN ConventionOperAmount ELSE 0 END),
			IQEE_Rendement_ARI =		SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_ARI_CONVENTION'		THEN ConventionOperAmount ELSE 0 END),
			IQEE_Subv_ARI =				SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_ARI_CONVENTION'			THEN ConventionOperAmount ELSE 0 END),
			IQEE_FraisChargésRQ =		SUM(isnull(RISCBQ.mMontant_Interets,0)) + sum(isnull(RISMMQ.mMontant_Interets,0))
			
		FROM 
			Un_ConventionOper CO
			JOIN un_oper O ON CO.Operid = O.OperID
			JOIN tblOPER_OperationsCategorie OC ON OC.cID_Type_Oper_Convention = CO.ConventionOperTypeID AND OC.cID_Type_Oper = O.Opertypeid
			JOIN tblOPER_CategoriesOperation COP ON COP.iID_Categorie_Oper = OC.iID_Categorie_Oper
			LEFT JOIN tblIQEE_ReponsesImpotsSpeciaux RISCBQ ON RISCBQ.iID_Paiement_Impot_CBQ = CO.ConventionOperID
			LEFT JOIN tblIQEE_ReponsesImpotsSpeciaux RISMMQ ON RISMMQ.iID_Paiement_Impot_MMQ = CO.ConventionOperID
		WHERE 
			LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtDateDe AND @dtDateA 
			AND	COP.vcCode_Categorie IN (
				'OPER_IQEE_RAPP_SUBV_BASE_CONVENTION',
				'OPER_IQEE_RAPP_SUBV_MAJORATION_CONVENTION', 
				'OPER_IQEE_RAPP_Rendement_Universitas_CONVENTION',
				'OPER_IQEE_RAPP_InteretRecuDeRQ_CONVENTION',
				'OPER_IQEE_RAPP_Rendement_ARI_CONVENTION',
				'OPER_IQEE_RAPP_SUBV_PAE_CONVENTION',
				'OPER_IQEE_RAPP_Rendement_PAE_CONVENTION',
				'OPER_IQEE_RAPP_SUBV_RIO_CONVENTION',
				'OPER_IQEE_RAPP_Rendement_RIO_CONVENTION',
				'OPER_IQEE_RAPP_SUBV_TRI_CONVENTION',
				'OPER_IQEE_RAPP_Rendement_TRI_CONVENTION',
				'OPER_IQEE_RAPP_SUBV_RIM_CONVENTION',
				'OPER_IQEE_RAPP_Rendement_RIM_CONVENTION',
				'OPER_IQEE_RAPP_SUBV_ARI_CONVENTION'
				,'OPER_IQEE_RAPP_Rendement_PRA_CONVENTION'
				)
		GROUP BY 
			CO.ConventionID

		UNION ALL

		-- IQEE Subv et Rendement TIN
		SELECT 
			CO.ConventionID,
			IQEE_SubvBaseRecu = 0,
			IQEE_SubvMajorationRecu = 0,
			IQEE_InteretRecuRQ = 0,
			IQEE_SubvTIN = SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_TIN_CONVENTION' AND TIO.iTINOperID IS NULL /* AND Cpny.companyname <> 'Universitas'*/ THEN ConventionOperAmount ELSE 0 END),
			IQEE_SubvTIOTIN = SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_TIN_CONVENTION' AND TIO.iTINOperID IS NOT NULL /* AND Cpny.companyname = 'Universitas'*/ THEN ConventionOperAmount ELSE 0 END),
			IQEE_SubvOUT = 0,
			IQEE_SubvTIOOUT = 0,
			IQEE_Rendement = 0,
			IQEE_RendementTIN = SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_TIN_CONVENTION' AND TIO.iTINOperID IS NULL /* AND Cpny.companyname <> 'Universitas'*/ THEN ConventionOperAmount ELSE 0 END),
			IQEE_RendementTIOTIN = SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_TIO_TIN_CONVENTION' AND TIO.iTINOperID IS NOT NULL /* AND Cpny.companyname = 'Universitas'*/ THEN ConventionOperAmount ELSE 0 END),
			IQEE_RendementOUT = 0,
			IQEE_RendementTIOOUT = 0,
			IQEE_Subv_PAE = 0,
			IQEE_Rendement_PAE = 0,
			IQEE_Rendement_PRA = 0,
			IQEE_Subv_RIO = 0,
			IQEE_Rendement_RIO = 0,
			IQEE_Subv_TRI = 0,
			IQEE_Rendement_TRI = 0,
			IQEE_Subv_RIM = 0,
			IQEE_Rendement_RIM = 0,
			IQEE_Rendement_ARI = 0,
			IQEE_Subv_ARI = 0,
			IQEE_FraisChargésRQ = 0
		FROM 
			Un_ConventionOper CO
			JOIN Un_oper O ON CO.Operid = O.OperID
			JOIN Un_TIN TIN ON CO.OperID = TIN.OperID
			JOIN Un_ExternalPlan EP ON EP.ExternalPlanID = TIN.ExternalPlanID
			JOIN Un_ExternalPromo EPR ON EPR.ExternalPromoID = EP.ExternalPromoID
			JOIN Mo_Company Cpny ON EPR.externalPromoID = Cpny.companyID 
			JOIN tblOPER_OperationsCategorie OC ON OC.cID_Type_Oper_Convention = CO.ConventionOperTypeID AND OC.cID_Type_Oper = O.Opertypeid
			JOIN tblOPER_CategoriesOperation COP ON COP.iID_Categorie_Oper = OC.iID_Categorie_Oper
			LEFT JOIN Un_TIO TIO ON TIO.iTINOperID = O.OperID
		WHERE 
			LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtDateDe AND @dtDateA 
			AND	COP.vcCode_Categorie IN ('OPER_IQEE_RAPP_SUBV_TIN_CONVENTION', 'OPER_IQEE_RAPP_Rendement_TIN_CONVENTION','OPER_IQEE_RAPP_Rendement_TIO_TIN_CONVENTION' )
		GROUP BY 
			CO.ConventionID

		UNION ALL

		-- IQEE Subv et Rendement OUT
		SELECT 
			CO.ConventionID,
			IQEE_SubvBaseRecu = 0,
			IQEE_SubvMajorationRecu = 0,
			IQEE_InteretRecuRQ = 0,
			IQEE_SubvTIN = 0,
			IQEE_SubvTIOTIN = 0,
			IQEE_SubvOUT = SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_OUT_CONVENTION' AND TIO.iOUTOperID IS NULL /*AND Cpny.companyname <> 'Universitas'*/ THEN ConventionOperAmount ELSE 0 END),
			IQEE_SubvTIOOUT = SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_SUBV_OUT_CONVENTION' AND TIO.iOUTOperID IS NOT NULL /*AND Cpny.companyname = 'Universitas'*/ THEN ConventionOperAmount ELSE 0 END),
			IQEE_Rendement = 0,
			IQEE_RendementTIN = 0,
			IQEE_RendementTIOTIN = 0,
			IQEE_RendementOUT = SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_OUT_CONVENTION' AND TIO.iOUTOperID IS NULL /*AND Cpny.companyname <> 'Universitas'*/ THEN ConventionOperAmount ELSE 0 END),
			IQEE_RendementTIOOUT = SUM(CASE WHEN COP.vcCode_Categorie = 'OPER_IQEE_RAPP_Rendement_OUT_CONVENTION' AND TIO.iOUTOperID IS NOT NULL /*AND Cpny.companyname =  'Universitas'*/ THEN ConventionOperAmount ELSE 0 END),
			IQEE_Subv_PAE = 0,
			IQEE_Rendement_PAE = 0,
			IQEE_Rendement_PRA = 0,
			IQEE_Subv_RIO = 0,
			IQEE_Rendement_RIO = 0,
			IQEE_Subv_TRI = 0,
			IQEE_Rendement_TRI = 0,
			IQEE_Subv_RIM = 0,
			IQEE_Rendement_RIM = 0,
			IQEE_Rendement_ARI = 0,
			IQEE_Subv_ARI = 0,
			IQEE_FraisChargésRQ = 0
		FROM 
			Un_ConventionOper CO
			JOIN Un_oper O ON CO.Operid = O.OperID
			JOIN Un_OUT ON CO.OperID = Un_OUT.OperID
			JOIN Un_ExternalPlan EP ON EP.ExternalPlanID = Un_OUT.ExternalPlanID
			JOIN Un_ExternalPromo EPR ON EPR.ExternalPromoID = EP.ExternalPromoID
			JOIN Mo_Company Cpny ON EPR.externalPromoID = Cpny.companyID --and Cpny.companyname <> 'Universitas' -- exclure GUI
			JOIN tblOPER_OperationsCategorie OC ON OC.cID_Type_Oper_Convention = CO.ConventionOperTypeID AND OC.cID_Type_Oper = O.Opertypeid
			JOIN tblOPER_CategoriesOperation COP ON COP.iID_Categorie_Oper = OC.iID_Categorie_Oper
			LEFT JOIN Un_TIO TIO ON TIO.iOUTOperID = O.OperID
		WHERE 
			LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtDateDe AND @dtDateA 
			AND	COP.vcCode_Categorie IN ('OPER_IQEE_RAPP_SUBV_OUT_CONVENTION','OPER_IQEE_RAPP_Rendement_OUT_CONVENTION') -- 58
		GROUP BY 
			CO.ConventionID

		) V
	JOIN dbo.Un_Convention C ON V.ConventionID = C.ConventionID
	JOIN dbo.Mo_human HS on C.subscriberID = HS.humanid
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	LEFT JOIN Un_ConventionYearQualif Y ON Y.ConventionID = C.ConventionID AND @dtDateA BETWEEN Y.EffectDate AND ISNULL(Y.TerminatedDate,@dtDateA+1)
	/*
	LEFT JOIN (
		SELECT
			Un.ConventionID,
			UnitQty = SUM(Un.UnitQty+ISNULL(UR.UnitQty, 0))
		FROM dbo.Un_Unit Un
		LEFT JOIN (
			-- Va chercher les unités résiliés après la date de fin de la période. Il faut additionner ces unités à ceux actuel des
			-- groupes d'unités pour connaître le nombre d'unités à la date de fin de période
 			SELECT
				UnitID,
				UnitQty = SUM(UnitQty)
			FROM Un_UnitReduction
			WHERE ReductionDate > @dtDateA -- Résiliation d'unités faites après la date de fin de période.
			GROUP BY UnitID
			) UR ON UR.UnitID = Un.UnitID
		GROUP BY Un.ConventionID
		) U ON U.ConventionID = C.ConventionID
	*/	
	WHERE
		(@cConventionno IS NULL OR C.ConventionNO = @cConventionno)
		AND (@iYearQualif  IS NULL OR ISNULL(Y.YearQualif,C.YearQualif) = @iYearQualif)
		AND (@iPlanID = 0 OR C.PlanID = @iPlanID) 
		--AND IQEE_FraisChargésRQ <> 0
	GROUP BY 	
		P.OrderOfPlanInReport,
		P.PlanID, -- ID unique du régime
		P.NomPlan,
		ISNULL(Y.YearQualif,C.YearQualif),
		C.ConventionNo,
		HS.LastName+', '+HS.FirstName
	ORDER BY
		P.OrderOfPlanInReport,
		YearQualif,
		C.ConventionNo


END