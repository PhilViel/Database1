/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psOPER_ObtenirLettreConfirmationRIO
Nom du service		:		Obtenir Lettre de confirmation RIO
But					:		Rapport de fusion word des contrats individuels
Facette				:		OPER
Reférence			:		UniAccés-Noyau-OPER

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iConnectID 			Identifiant de la connection
						iUnitID			ID du groupe d'unité
						iDocAction			Identifiant de l'action à prendre avec le document

Exemple d'appel:
				@iConnectID  = 198414, --ID de connection de l'usager
				@iUnitID = 318766, --ID du blob
				@iDocAction = 0 -- Identifiant de l'action à prendre avec le document

				Resultats:
				Prenom Suscripteur: Johanne
				Nom Suscripteur: Dupont
				Prenom Beneficiaire: Simon
				Nom Beneficiaire: Bélanger
				Nom Representant: Dodier
				Prenom Representant: Monette
				ConventionNoDestination: T-20080501006
				ConventionNoSource: 1409963
		
Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													Code de retour						C'est un code de retour qui indique si la requête s'est terminée avec succès ou non
																						-- >0  : Tout ok
																						-- <=0 : Erreurs
																						-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
																						-- 	-2 : Pas de document(s) de généré(s)
Parametres d'entrée : paramétre 					Description							
					   -----------------			---------------------------			
					@iConnectID						ID de connexion de l'usager
					@iUnitIDs						ID du blob contenant les UnitID séparés par des « , » 
													des groupes d’unités dont on veut générer le document.  		
					@iDocAction						ID du type d'action à entreprendre.

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-06-26					Nassim Rekkab							Création de procédure stockée
						2009-12-14					Pierre-Luc Simard						Ajout de l'IQEE et correction des modalités pour utiliser celle du groupe d'unités Individuel
						2010-11-24					Donald Huppé							Ajout des champs PlanDesc et Age pour gérer les RIO de Reeeflex et "Select 2000 Plan B" (GLPI 4661)
						2010-12-03					Donald Huppé							Ajout de la gestion des erreurs
						2011-04-04					Frédérick Thibault						Modifications pour Prospectus 2010-2011 (FT1)
						2012-03-29					Donald Huppé							Faire un left join sur la recherche des frais de service. 
																							Pour éviter que la lettre ne soit pas généré depuis qu'il n'y a plus de frais de service
						2012-03-30					Donald Huppé							Ne plus faire de Left join sur les frais car ça peut dupliquer les lettre. enlever le join complètement
																							et faire un distinct dans #Letter
						2018-11-08					Maxime Martel							Utilisation de planDesc_ENU et regroupement regime de la table plan
                        2018-11-12                  Pierre-Luc Simard                       N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirLettreConfirmationRIO](
	@iConnectID INTEGER, -- ID de connexion de l'usager
	@iUnitIDs	INTEGER, -- ID du blob contenant les UnitID séparés par des « , » des groupes d’unités dont on veut générer le document.  		
	@iDocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

SELECT 1/0

/*
BEGIN TRY

	DECLARE 		
		@iDocTypeID INTEGER,
		@vcNomUsager VARCHAR(77),
		@iBeneficiaireID INTEGER,
		@dtDateNaissance DATETIME,
		@dtAujourdhui DATETIME,
		@iAgeBeneficiaire INTEGER,
		--@iModalID INTEGER,
		@iPlanID INTEGER,
		@iStatut INT

	SET @dtAujourdhui = GetDate()	

	CREATE TABLE #UnitInReport (
		UnitID INTEGER PRIMARY KEY )

	INSERT INTO #UnitInReport
		SELECT DISTINCT Val
		FROM dbo.FN_CRQ_BlobToIntegerTable(@iUnitIDs)

	CREATE TABLE #ConvInReport (
			ConventionID INTEGER PRIMARY KEY )
		
	INSERT INTO #ConvInReport
		SELECT DISTINCT 
			ConventionID
		FROM #UnitInReport UIR
		JOIN dbo.Un_Unit U ON U.UnitID = UIR.UnitID
		WHERE U.IntReimbDate IS NOT NULL 

	-- Table temporaire qui contient le document
	CREATE TABLE #Letter(
		ConventionID INTEGER,
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		LetterMedDate VARCHAR(75),
		ConventionNo VARCHAR(75),
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		SubscriberAddress VARCHAR(75),
		SubscriberCity VARCHAR(100),
		SubscriberState VARCHAR(75),
		SubscriberZipCode VARCHAR(75),
		SubscriberPhone VARCHAR(75), 
		LongSexName VARCHAR(75),
		ShortSexName VARCHAR(75),
		YearQualif INTEGER,
		OperAmount VARCHAR(75),
		Username VARCHAR(77),
		ConventionSourceNo VARCHAR(75), --Ajouté (tblOPER_OperationsRIO --iID_Convention_Source)
		ConventionDestNo VARCHAR(75), --Ajouté (tblOPER_OperationsRIO -- iID_Convention_Destination)
		FeeByUnit VARCHAR(50), --Ajouté (un_modal -- FeeByUnit)
		Fee VARCHAR(50), -- FT1

		OperScee VARCHAR(50), --Ajouté (table un_cesp  -- fCESG)
		OperSceeSupp VARCHAR(100),--(table un_cesp --fACESG)		
		OperInt VARCHAR(50), --(table un_ConventionOper -- ConventionOperAmount)
		OperIQEE VARCHAR(50), --(table un_ConventionOper -- ConventionOperAmount)
		OperIQEEInt VARCHAR(50), --(table un_ConventionOper -- ConventionOperAmount)
		OperIQEEtxt VARCHAR(250), --(table un_ConventionOper -- ConventionOperAmount)	
		OperBEC VARCHAR(100),--(table un_cesp --fCLB),
		RetourChariot VARCHAR(120),
		BeneficiaryFirstName VARCHAR(30),
		BeneficiaryLastName VARCHAR(30),
		--RepresentantFirstName VARCHAR(30),
		--RepresentantLastName VARCHAR(30),
		PlanDesc VARCHAR(75),
		Age	VARCHAR(2)
	)

	-- Va chercher le bon type de document
	SELECT 
		@iDocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'RIO'

	SELECT 
		@vcNomUsager = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON CO.UserID = U.UserID
	JOIN dbo.Mo_Human HU ON HU.HumanID = U.UserID
	WHERE Co.ConnectID = @iConnectID

	--Bénéficiaire de la convention individuelle
	SELECT 
		@iBeneficiaireID = BeneficiaryID, 
		@iPlanID = C.PlanID
	FROM #UnitInReport UIR
	JOIN dbo.Un_Unit U ON UIR.UnitID = U.UnitID
	JOIN tblOPER_OperationsRIO OpRIO ON OpRIO.iID_Unite_Source= U.UnitID
	JOIN dbo.Un_Convention C ON OpRio.iID_Convention_Destination = C.ConventionID

	--Date de naissance du bénéficiaire
	SELECT 
		@dtDateNaissance = MH.BirthDate
	FROM dbo.Mo_Human MH
	WHERE HumanId = @iBeneficiaireID	

	-- Appel de la fonction pour avoir l'age du beneficiaire
	EXEC @iAgeBeneficiaire = fn_Mo_Age @dtDateNaissance, @dtAujourdhui

	/*
	--Va chercher la modalité pour les frais
	SELECT 
		@iModalID = Mod.ModalID
	FROM Un_Modal Mod
	WHERE Mod.PlanID = @iPlanID
		AND Mod.PmtbyYearID = 1
		AND Mod.PmtQty = 1 
		AND Mod.BenefAgeOnBegining = @iAgeBeneficiaire
	*/
	
	-- Remplis la table temporaire
	INSERT INTO #Letter
		SELECT distinct
			CON.ConventionID,
			T.DocTemplateID,
			SUB.LangID,
			LetterMedDate = dbo.fn_Mo_DateToLongDateStr (@dtAujourdhui, SUB.LangID),
			CON.ConventionNo,
			SubscriberFirstName = SUB.FirstName,
			SubscriberLastName = SUB.LastName,
			SubscriberAddress = A.Address,
			SubscriberCity = A.City,
			SubscriberState = A.StateName,
			SubscriberZipCode = dbo.fn_Mo_FormatZIP(A.ZipCode, A.CountryID),
			SubscriberPhone = dbo.fn_Mo_FormatPhoneNo(A.Phone1,A.CountryID),
			LongSexName = ISNULL(S.LongSexName,'???'),			
			ShortSexName = ISNULL(S.ShortSexName,'???'),
			CON.YearQualif,
			
			-- FT1
			OperAmount = dbo.fn_Mo_MoneyToStr(ABS(CO.Cotisation) /*- ISNULL(FRS2.mMontant_Frais, 0)*/ - isnull(FRS.Fee, 0), SUB.LangID, 0),
			--OperAmount = dbo.fn_Mo_MoneyToStr(ABS(CO.Cotisation) - SUM(ISNULL(FRS2.mMontant_Frais, 0)), SUB.LangID, 0),
			
			Username = @vcNomUsager,
			ConventionSourceNo  = CON.ConventionNo,
			ConventionDestNo = CONDestination.ConventionNo, 
			FeeByUnit = dbo.fn_Mo_MoneyToStr(MO.FeeByUnit,SUB.LangID, 0), 
			
			Fee = dbo.fn_Mo_MoneyToStr(FRS.Fee, SUB.LangID, 0), -- FT1
			
			OperScee = dbo.fn_Mo_MoneyToStr(ISNULL(CS.fCESG,0),SUB.LangID, 0), 
			OperSceeSupp = (
						CASE 
							--WHEN SUM(CS.fACESG) = 0 THEN  ' '
							WHEN (CS.fACESG) = 0 THEN  ' '
						ELSE CASE WHEN SUB.LANGID = 'FRA'  THEN
							 ', la SCEE supplémentaire au montant de ' +  dbo.fn_Mo_MoneyToStr((CS.fACESG),SUB.LangID, 1) 
								ELSE
							 ', the additional CESG totalling $' +  dbo.fn_Mo_MoneyToStr((CS.fACESG),SUB.LangID, 0) 
								END
						END),
			OperInt = dbo.fn_Mo_MoneyToStr(ISNULL(COP.OperInt,0), SUB.LangID, 0),
			OperIQEE = dbo.fn_Mo_MoneyToStr(ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0), SUB.LangID, 0),
			OperIQEEInt = dbo.fn_Mo_MoneyToStr(ISNULL(COP.RendIQEE,0) + ISNULL(COP.RendIQEEMaj,0) + ISNULL(COP.RendIQEETin,0), SUB.LangID, 0),
			OperIQEEtxt = (
						CASE WHEN SUB.LANGID = 'FRA'  THEN 
							CASE 
								WHEN (ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0) = 0) -- Sans IQEE et sans intérêt IQEE   
										AND ISNULL(COP.RendIQEE,0) + ISNULL(COP.RendIQEEMaj,0) + ISNULL(COP.RendIQEETin,0) = 0 
									THEN ''
								WHEN (ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0) <> 0) -- Avec IQEE et sans intérêt IQEE  
										AND ISNULL(COP.RendIQEE,0) + ISNULL(COP.RendIQEEMaj,0) + ISNULL(COP.RendIQEETin,0) = 0 
									THEN ' De même, nous avons transféré à votre nouveau régime l''Incitatif Québécois à l''Épargne-Études (IQEE) au montant de ' +  dbo.fn_Mo_MoneyToStr(ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0), SUB.LangID, 0) + ' $.'
								WHEN (ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0) <> 0) -- Avec IQEE et avec intérêt IQEE  
										AND ISNULL(COP.RendIQEE,0) + ISNULL(COP.RendIQEEMaj,0) + ISNULL(COP.RendIQEETin,0) <> 0 
									THEN ' De même, nous avons transféré à votre nouveau régime l''Incitatif Québécois à l''Épargne-Études (IQEE) au montant de ' +  dbo.fn_Mo_MoneyToStr(ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0), SUB.LangID, 0) + ' $ et l’intérêt de ' +  dbo.fn_Mo_MoneyToStr(ISNULL(COP.RendIQEE,0) + ISNULL(COP.RendIQEEMaj,0) + ISNULL(COP.RendIQEETin,0), SUB.LangID, 0) + ' $.'
							ELSE ''
							END
						ELSE
							CASE 
								WHEN (ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0) = 0) -- Sans IQEE et sans intérêt IQEE   
										AND ISNULL(COP.RendIQEE,0) + ISNULL(COP.RendIQEEMaj,0) + ISNULL(COP.RendIQEETin,0) = 0 
									THEN ''
								WHEN (ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0) <> 0) -- Avec IQEE et sans intérêt IQEE  
										AND ISNULL(COP.RendIQEE,0) + ISNULL(COP.RendIQEEMaj,0) + ISNULL(COP.RendIQEETin,0) = 0 
									THEN ' Also, we have transferred the amounts of $' + dbo.fn_Mo_MoneyToStr(ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0), SUB.LangID, 0)  + ' to your scholarship plan, this sum represents the Quebec Education Savings Incentive (QESI).'
								WHEN (ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0) <> 0) -- Avec IQEE et avec intérêt IQEE  
										AND ISNULL(COP.RendIQEE,0) + ISNULL(COP.RendIQEEMaj,0) + ISNULL(COP.RendIQEETin,0) <> 0 
									THEN ' Also, we have transferred the amounts of $' + dbo.fn_Mo_MoneyToStr(ISNULL(COP.IQEE,0) + ISNULL(COP.IQEEMaj,0), SUB.LangID, 0) + ' and $' + dbo.fn_Mo_MoneyToStr(ISNULL(COP.RendIQEE,0) + ISNULL(COP.RendIQEEMaj,0) + ISNULL(COP.RendIQEETin,0), SUB.LangID, 0) + ' to your scholarship plan, these sums represent the Quebec Education Savings Incentive (QESI) and its interest.'
							ELSE ''
							END
						END),
			OperBEC = (
						CASE 
							--WHEN SUM(CS.fCLB) = 0 THEN ' '
							WHEN (CS.fCLB) = 0 THEN ' '
						ELSE CASE WHEN SUB.LANGID = 'FRA' THEN
							  ', le BEC au montant de ' + dbo.fn_Mo_MoneyToStr((CS.fCLB),SUB.LangID, 1) 
								ELSE
							  ', the BEC totalling ' + dbo.fn_Mo_MoneyToStr((CS.fCLB),SUB.LangID, 1) 
								END
						END),
			RetourChariot = (
						CASE 
							--WHEN ISNULL(SUM(CS.fACESG),0) = 0 AND ISNULL(SUM(CS.fCLB),0) = 0  THEN  '1111111111111111111111111111111111111111111111111111111111111111111111111111111' + CHAR(13)+ CHAR(13)
							WHEN ISNULL((CS.fACESG),0) = 0 AND ISNULL((CS.fCLB),0) = 0  THEN  '1111111111111111111111111111111111111111111111111111111111111111111111111111111' + CHAR(13)+ CHAR(13)
						ELSE  ''
						END), -- Il faut prendre note que les caractères dans le document word pour ce champ sont en blanc, donc invisible
			BeneficiaryFirstName = BEN.FirstName, 
			BeneficiaryLastName = BEN.LastName, 
			--RepresentantFirstName = REP.FirstName,
			--RepresentantLastName = REP.LastName,
			PlanDesc = upper(case when SUB.LangID = 'ENU' then pl.PlanDesc_ENU else PL.PlanDesc end), 
			Age = case when PL.iID_Regroupement_Regime = 2 then '18' else '19' end -- regroupement regime 2 = reeeflex
		FROM dbo.Un_Convention CON
		JOIN tblOPER_OperationsRIO OpRIO ON OpRIO.iID_Convention_Source = CON.ConventionID AND OpRIO.bRIO_Annulee = 0 -- Ajoute
		JOIN dbo.Un_Convention CONDestination ON CONDestination.ConventionID = OpRIO.iID_Convention_Destination --Ajoute
		JOIN dbo.Un_Unit UDest ON UDest.ConventionID = CONDestination.ConventionID
		--JOIN dbo.Un_Unit U ON U.ConventionID = CON.ConventionID 
		--JOIN #UnitInReport UIR ON UIR.UnitID = U.UnitID
		JOIN #ConvInReport CIR ON CIR.ConventionID = CON.ConventionID
		
		-- FT1
		JOIN (
			SELECT 
				SUM(Cotisation) AS Cotisation, 
				UnitID, 
				RIO.iID_CONVENTION_SOURCE 
			FROM Un_Cotisation C1
			JOIN tblOper_OperationsRIO RIO ON (C1.OperId = RIO.iID_Oper_RIO) AND RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
			GROUP BY 
				UnitId,  
				iID_CONVENTION_SOURCE
			) CO ON CO.UnitID = UDest.UnitID and CO.iID_CONVENTION_SOURCE = OpRIO.iID_Convention_Source
		
		--JOIN (
		--	SELECT 
		--		SUM(Cotisation) AS Cotisation, 
		--		UnitID,
		--		RIO.iID_CONVENTION_DESTINATION
		--	FROM Un_Cotisation C1
		--	JOIN tblOper_OperationsRIO RIO ON (C1.OperId = RIO.iID_Oper_RIO) AND RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
		--	GROUP BY 
		--		UnitId,  
		--		iID_CONVENTION_DESTINATION
		--	--) CO ON CO.UnitID = UDest.UnitID and CO.iID_CONVENTION_DESTINATION = OpRIO.iID_Convention_Destination
		--	) CO ON CO.UnitID = U.UnitID AND CON.ConventionID = OpRIO.iID_Convention_Source
		
		JOIN Un_Oper O ON O.OperID = OpRIO.iID_OPER_RIO AND O.OperTypeID = 'RIO'
		JOIN dbo.Mo_Human SUB ON SUB.HumanID = CON.SubscriberID
		JOIN dbo.Mo_Adr A ON A.AdrID = SUB.AdrID
		JOIN dbo.Mo_Human BEN ON BEN.HumanID = CON.BeneficiaryID
		JOIN Mo_Sex S ON SUB.LangID = S.LangID AND SUB.SexID = S.SexID
		--JOIN dbo.Mo_Human REP ON REP.HumanID = U.RepID
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @iDocTypeID
			  AND (DocTemplateTime < @dtAujourdhui)
			GROUP BY 
				LangID, 
				DocTypeID
			) V ON V.LangID = SUB.LangID
		JOIN CRQ_DocTemplate T ON V.DocTypeID = T.DocTypeID AND V.DocTemplateTime = T.DocTemplateTime AND T.LangID = SUB.LangID
		JOIN Un_Plan PL ON PL.PlanID = CON.PlanID --Ajoute
		JOIN Un_Modal MO ON MO.ModalID = UDest.ModalID --@iModalID -- Ajoute
		LEFT JOIN (
			SELECT 
				ConventionID, 
				RIO.iID_CONVENTION_SOURCE,
				IQEE = SUM (
					CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'CBQ' THEN ISNULL(UCO.ConventionOperAmount,0)
					ELSE 0
					END
					),
				RendIQEE = SUM (
					CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('ICQ', 'MIM', 'IIQ') THEN ISNULL(UCO.ConventionOperAmount,0)
					ELSE 0
					END
					),
				IQEEMaj = SUM (
					CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'MMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
					ELSE 0
					END
					),
				RendIQEEMaj	= SUM (
					CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'IMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
					ELSE 0
					END
					),
				RendIQEETin	= SUM (
					CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
					ELSE 0
					END
					),
				OperInt	= SUM ( -- Tous sauf l'IQEEE
					CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') NOT IN ('CBQ', 'ICQ', 'MIM', 'IIQ', 'MMQ', 'IMQ', 'III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
					ELSE 0
					END
					)
			FROM Un_ConventionOper UCO 
			JOIN tblOper_OperationsRIO RIO ON (UCO.OperId = RIO.iID_Oper_RIO) AND RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
			GROUP BY 
				ConventionID,
				RIO.iID_CONVENTION_SOURCE
			) COP ON COP.ConventionID = OpRIO.iID_Convention_Destination AND COP.iID_CONVENTION_SOURCE = OpRIO.iID_Convention_Source
		LEFT JOIN (
			SELECT 
				ConventionID, 
				RIO.iID_CONVENTION_SOURCE, 
				SUM(fCESG) AS fCESG, 
				SUM(fACESG) AS fACESG ,
				SUM(fCLB) AS fCLB
			FROM Un_CESP UC 
			JOIN tblOper_OperationsRIO RIO ON (UC.OperId = RIO.iID_Oper_RIO) AND RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
			GROUP BY 
				ConventionID, 
				RIO.iID_CONVENTION_SOURCE
			) CS ON CS.ConventionID = OpRIO.iID_Convention_Destination AND CS.iID_CONVENTION_SOURCE = OpRIO.iID_Convention_Source
		
		LEFT JOIN ( -- Recherche des frais transférés - FT1
			SELECT	 ConventionID = CN.ConventionID
					,Fee = ABS(SUM(CT.Fee))
			FROM dbo.Un_Unit UN
			JOIN dbo.Un_Convention CN ON CN.ConventionID = UN.ConventionID
			JOIN Un_Cotisation CT ON CT.UnitID = UN.UnitID
			JOIN Un_Oper OP ON OP.OperID = CT.OperID
			--WHERE CN.ConventionID = OpRIO.iID_Convention_Source
			WHERE OP.OperTypeID = 'RIO'
			GROUP BY CN.ConventionID
			) FRS ON FRS.ConventionID = OpRIO.iID_Convention_Source
		/*
		left JOIN ( -- Recherche des frais de service appliqués sur la convention individuelle
				SELECT	 iID_Operation_Enfant = AO.iID_Operation_Enfant
						,iID_Operation_Parent = AO.iID_Operation_Parent
						,mMontant_Frais		= SUM(ISNULL(FR.mMontant_Frais, 0) + ISNULL(FT1.mMontant_Taxe, 0) + ISNULL(FT2.mMontant_Taxe, 0))
				FROM tblOPER_AssociationOperations AO
				JOIN tblOPER_Frais FR ON FR.iID_Oper = AO.iID_Operation_Enfant 

				JOIN tblOPER_FraisTaxes	FT1	ON	FT1.iID_Frais			= FR.iID_Frais
											AND	FT1.iID_Type_Parametre	= (	SELECT iID_Type_Parametre
																			FROM tblGENE_TypesParametre
																			WHERE vcCode_Type_Parametre = 'OPER_TAXE_TPS')
				JOIN tblOPER_FraisTaxes	FT2	ON	FT2.iID_Frais			= FR.iID_Frais
											AND	FT2.iID_Type_Parametre	= (	SELECT iID_Type_Parametre
																			FROM tblGENE_TypesParametre
																			WHERE vcCode_Type_Parametre = 'OPER_TAXE_TVQ')
				GROUP BY AO.iID_Operation_Enfant
						,AO.iID_Operation_Parent
				--		,mMontant_Frais
				
				) FRS2 ON FRS2.iID_Operation_Parent = opRIO.iID_Oper_RIO
				--) FRS2 ON FRS2.iID_Operation_Enfant = OpRio.iID_Oper_RIO
		*/
		/*WHERE U.IntReimbDate IS NOT NULL 
		GROUP BY 
			CON.ConventionID,
			T.DocTemplateID,
			SUB.LangID, 
			CON.ConventionNo,
			SUB.LastName,
			SUB.FirstName,
			A.Address, 
			A.City,
			A.StateName, 
			A.ZipCode, 
			A.CountryID,
			A.Phone1,
			A.CountryID,
			S.LongSexName, 
			S.ShortSexName, 
			CON.YearQualif,
			CO.Cotisation,
			FRS2.mMontant_Frais,
			MO.FeeByUnit,			
			FRS.Fee,
			CONDestination.ConventionNo,				
			CS.fCESG,
			CS.fACESG,
			CS.fCLB, 
			COP.IQEE,
			COP.RendIQEE,
			COP.IQEEMaj,
			COP.RendIQEEMaj,
			COP.RendIQEETin,
			COP.OperInt,			
			BEN.FirstName,
			BEN.LastName, 
			REP.FirstName,
			REP.LastName,
			CS.fCLB,
			PlanDesc,
			PL.PlanID
*/
		ORDER BY
			T.DocTemplateID,
			SUB.LastName,
			SUB.FirstName,
			CON.ConventionNo

	-- Gestion des documents
	IF @iDocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@iConnectID,
				@dtAujourdhui,
				ISNULL(ConventionNo,''),
				ISNULL(SubscriberLastName,'')+','+ISNULL(SubscriberFirstName,''),
				'', 

				ISNULL(LangID,'')+';'+
				ISNULL(LetterMedDate,'')+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';'+
				ISNULL(SubscriberAddress,'')+';'+
				ISNULL(SubscriberCity,'')+';'+
				ISNULL(SubscriberState,'')+';'+
				ISNULL(SubscriberZipCode,'')+';'+
				ISNULL(SubscriberPhone,'')+';'+
				ISNULL(LongSexName,'')+';'+
				ISNULL(ShortSexName,'')+';'+
				ISNULL(CAST(YearQualif AS VARCHAR),'')+';'+
				ISNULL(OperAmount,'')+';'+
				ISNULL(Username,'')+';' +
				ISNULL(ConventionSourceNo,'')+';'+ 
				ISNULL(ConventionDestNo,'')+';'+
				ISNULL(CAST(FeeByUnit AS VARCHAR),'')+';'+
				ISNULL(CAST(Fee AS VARCHAR),'')+';'+
				ISNULL(OperScee ,'')+';'+
				ISNULL(OperSceeSupp ,'')+';'+
				ISNULL(OperInt ,'')+';'+
				ISNULL(OperIQEE ,'')+';'+
				ISNULL(OperIQEEInt ,'')+';'+
				ISNULL(OperIQEEtxt ,'')+';'+
				ISNULL(OperBEC ,'')+';'+
				ISNULL(RetourChariot ,'')+';'+
				ISNULL(BeneficiaryFirstName,'')+';'+
				ISNULL(BeneficiaryLastName,'')+';'+
				ISNULL(NULL,'')+';'+ --ISNULL(RepresentantFirstName,'')+';'+
				ISNULL(NULL,'')+';'+ --ISNULL(RepresentantLastName,'')+';'+
				ISNULL(PlanDesc,'')+';'+
				ISNULL(Age,'')+';'
			FROM #Letter

		-- Fait un lien entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			JOIN dbo.Un_Convention C ON C.ConventionNo = D.DocGroup1
			LEFT JOIN CRQ_DocLink L ON L.DocLinkID = C.ConventionID AND L.DocLinkType = 1 AND L.DocID = D.DocID
			WHERE L.DocID IS NULL
				AND T.DocTypeID = @iDocTypeID
				AND D.DocOrderTime = @dtAujourdhui
				AND D.DocOrderConnectID = @iConnectID	

		IF @iDocAction = 2
			-- Dans le cas que l'usager a choisi imprimer et garder la trace dans la gestion 
			-- des documents, on indique qu'il a déjà été imprimé pour ne pas le voir dans 
			-- la queue d'impression
			INSERT INTO CRQ_DocPrinted(DocID, DocPrintConnectID, DocPrintTime)
				SELECT
					D.DocID,
					@iConnectID,
					@dtAujourdhui
				FROM CRQ_Doc D 
				JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
				LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @iConnectID AND P.DocPrintTime = @dtAujourdhui
				WHERE P.DocID IS NULL
					AND T.DocTypeID = @iDocTypeID
					AND D.DocOrderTime = @dtAujourdhui
					AND D.DocOrderConnectID = @iConnectID	

		-- Inscrit l'étape 6 du remboursement intégral en batch
		INSERT INTO Un_IntReimbStep (
				UnitID,
				iIntReimbStep,
				dtIntReimbStepTime,
				ConnectID )
			SELECT
				UIR.UnitID,
				6,
				GETDATE(),
				@iConnectID
			FROM #UnitInReport UIR
			JOIN dbo.Un_Unit U ON U.UnitID = UIR.UnitID
			JOIN #Letter L ON L.ConventionID = U.ConventionID				
	END

	DROP TABLE #UnitInReport

	-- Produit un dataset pour la fusion
	SELECT 
		DocTemplateID,
		LangID,
		LetterMedDate,
		SubscriberFirstName,
		SubscriberLastName,
		SubscriberAddress,
		SubscriberCity,
		SubscriberState,
		SubscriberZipCode,
		SubscriberPhone,
		LongSexName,
		ShortSexName,
		YearQualif,
		OperAmount,
		Username,
		ConventionSourceNo,	
		ConventionDestNo,
		FeeByUnit,
		Fee,
		OperScee,
		OperSceeSupp,
		OperInt,
		OperIQEE,
		OperIQEEInt,
		OperIQEEtxt,
		OperBEC,
		RetourChariot,
		BeneficiaryFirstName, 
		BeneficiaryLastName, 
		RepresentantFirstName = NULL,
		RepresentantLastName = NULL,
		PlanDesc,
		Age
	FROM #Letter 
	WHERE @iDocAction IN (1,2)
	ORDER BY SubscriberLastName, SubscriberFirstName

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @iDocTypeID)
			  AND (DocTemplateTime < @dtAujourdhui))
		BEGIN 
			SET @iStatut = -1  -- Pas de template d'entré ou en vigueur pour ce type de document
			RETURN @iStatut
		END
		
	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM #Letter)
		BEGIN
			SET @iStatut = -2  -- Pas de document(s) de généré(s)
			RETURN @iStatut
		END
	ELSE 
		BEGIN
			SET @iStatut = 1  -- Tout a bien fonctionné
		END

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #Letter
	
END TRY

BEGIN CATCH
	DECLARE		 
		@iErrSeverite	INT
		,@iErrStatut	INT
		,@vcErrMsg		NVARCHAR(1024)
		
	SELECT
		@vcErrMsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
		,@iErrStatut	= ERROR_STATE()
		,@iErrSeverite	= ERROR_SEVERITY()
		,@iStatut		= -3
		
	RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
END CATCH

RETURN @iStatut
*/	
END