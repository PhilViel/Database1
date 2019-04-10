/********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_SumCESPByPlanAndQualifYear
Description         :	Rapport : Sommaire du PCEE par régime et année de qualification.
Valeurs de retours  :	Dataset :
									iPlanID					INTEGER			ID unique du régime
									vcPlanDesc				VARCHAR(75)		Description du régime	
									iYearQualif				INTEGER			Année de qualification aux bourses de la convention. C'est l'année à laquelle le bénéficiaire de la convention pourra toucher sa première bourse pour cette convention s'il rempli les conditions.
									iConventionCount		INTEGER			Nombre de convention
									fUnitQty				MONEY			Nombre d’unités
									fCESG					MONEY			SCEE
									fACESG					MONEY			SCEE+
									fCLB					MONEY			BEC
									fINS					MONEY			Intérêts créditeurs - SCEE
									fCESG_ACESG_TIN			MONEY			SCEE et SCEE+ reçue (TIN)
									fCLB_TIN				MONEY			BEC reçu (TIN)
									fCESG_ACESG_OUT			MONEY			SCEE et SCEE+ payée (OUT)
									fCLB_OUT				MONEY			BEC payé (OUT)
									fCESPInt_TIN			MONEY			Intérêts PCEE TIN reçus
									fCESPInt_OUT			MONEY			Intérêts SCEE, intérêts SCEE+, intérêts BEC et intérêts payés (OUT)
									fCESPOfScholarship		MONEY			SCEE, SCEE+, BEC et Intérêts versés en bourse.
									fTotal					MONEY			fCESG+fACESG+fCLB+fINS+fCESG_ACESG_TIN+fCLB_TIN+
																			fCESG_ACESG_OUT+fCLB_OUT+fCESPInt_TIN+fCESPInt_OUT+
																			fCESPOfScholarship

Note                :			ADX0001171	IA	2006-11-15	Bruno Lapointe			Création.
								ADX0002426	BR	2007-05-22	Alain Quirion			Modification : Un_CESP au lieu de Un_CESP900
												2009-12-10	Jean-François Gauthier	Modification pour remplacer INT par IN+/IN-
												2009-12-17	Jean-François Gauthier	Intégration modif. Rémy
												2010-01-15	Donald Huppé			remplacer fnOPER_ObtenirTypesOperationConvCategorie par fnOPER_ObtenirTypesOperationCategorie
												2010-02-18	Donald Happé			Ajout de RIO et TIO
																					Reduire le nombre de select causé par @bAll
												2010-04-16	Donald Huppé			GLPI 3157
												2010-12-10	Donald Huppé			Ajout des ARI dans le calcul du rendement SCEE (fINS)
												2011-03-28	Donald Huppé			Tranférer les ARI de rendement dans une nouvelle colonne fINS_ARI
																					Nouvelle colonne des ARI de Subvention
												2011-05-18	Donald Huppé			GLPI 5510 Ajout de TRI et RIM
												2011-06-23	Donald Huppé			GLPI 5715 : Ajout du groupe de régime
												2012-04-30	Donald Huppé			Remplacer operdate dans les clause where par LEFT(CONVERT(VARCHAR, OperDate, 120), 10)
																					Et ne plus transformer dtEnd en HH;mm:SS
												2013-08-15	Donald Huppé			Enlever le PrimaryKey dans #tOperTIO car au 2013-08-14 ça plante à cause d'un renversement de TIO dans U-20090615002
												2014-02-11	Donald Huppé			Ajout du paramètre @ConventionStateID
												2016-05-16	Donald Huppé			JIRA TI-2317 : Ajout du PRA
                                                2018-11-08  Pierre-Luc Simard       Utilisation du nom du plan complet
												
exec RP_UN_SumCESPByPlanAndQualifYear 0, '2016-02-01', '2016-04-26', 17, 'FRM'
												
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_SumCESPByPlanAndQualifYear] (	
	@bAll INTEGER, -- Champ booléen qui détermine si l'on veut le rapport sans période (1) ou pour une période saisie (0).
	@dtStart DATETIME, -- Date de début saisie
	@dtEnd DATETIME, -- Date de fin saisie
	@iColumnFilter INTEGER,--	Filtre sur les colonnes associées à des comptes G/L du rapport :
									--		0 = Une des colonnes (pas de filtre)
									--		1 = SCEE
									--		2 = SCEE+
									--		3 = BEC
									--		4 = Intérêts créditeurs - SCEE
									--		5 = SCEE et SCEE+ reçu (TIN)
									--		6 = BEC reçu (TIN)
									--		7 = SCEE et SCEE+ payée (OUT)
									--		8 = BEC payé (OUT)
									--		9 = Intérêts SCEE, SCEE+ et BEC reçus (TIN)
									--		10 = Intérêts SCEE, SCEE+ et BEC payés (OUT)
									--		11 = SCEE, SCEE+, BEC et Intérêts versés en bourse.
									--		12 = Rendements transférés (ARI)
									--		13 = Subventions transférés (ARI)
									--		14 = Subvention ou rendement RIO
									--		15 = Subvention ou rendement TRI
									--		16 = Subvention ou rendement RIM
									--		17 = Rendement PRA
	@ConventionStateID varchar(3) = 'ALL'
				)
									
AS
BEGIN

	DECLARE @vcOPER_RENDEMENT_POSITIF_NEGATIF VARCHAR(200)

	SET @vcOPER_RENDEMENT_POSITIF_NEGATIF = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('OPER_RENDEMENT_POSITIF_NEGATIF')

	IF @bAll = 1
	BEGIN
		-- Si on sort pour tous, alors on met comme date de début 01/01/1950 et date de fin la date du jour.
		SELECT
			@dtStart = '1950-01-01',
			@dtEnd = dbo.FN_CRQ_DateNoTime(GETDATE())
	END
	--SET @dtEnd = DATEADD(s, -1, DATEADD(DAY, 1, @dtEnd))

	-- Applique le filtre des états de conventions.
	CREATE TABLE #tConventionState (
		ConventionID INTEGER PRIMARY KEY )

	INSERT INTO #tConventionState
		SELECT 
			V.ConventionID
		FROM ( -- Retourne le plus grand ID pour la plus grande date de début d'un état par convention
			SELECT 		
				T.ConventionID,
				ConventionConventionStateID = MAX(CCS.ConventionConventionStateID)
			FROM (-- Retourne la plus grande date de début d'un état par convention
				SELECT 
					S.ConventionID,
					MaxDate = MAX(S.StartDate)
				FROM Un_ConventionConventionState S
				JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
				WHERE LEFT(CONVERT(VARCHAR, S.StartDate, 120), 10) <= @dtEnd -- État à la date de fin de la période
				GROUP BY S.ConventionID
				) T
			JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
			GROUP BY T.ConventionID
			) V
		JOIN Un_ConventionConventionState CCS ON V.ConventionConventionStateID = CCS.ConventionConventionStateID
		WHERE CCS.ConventionStateID = @ConventionStateID
		or @ConventionStateID = 'ALL'
			/*
			CCS.ConventionStateID = 'REE' -- L'état REEE
				OR CCS.ConventionStateID = 'FRM' -- Fermé compte comme REE
				OR CCS.ConventionStateID = 'TRA' -- Transitoire
				OR CCS.ConventionStateID = 'PRP' -- En proposition
			*/
	CREATE TABLE #tOperTIO(
		OperID INT,-- PRIMARY KEY,
		iTioId integer
		)

	INSERT INTO #tOperTIO
		SELECT 
			o.OperID,
			TioTIN.iTioId
		FROM Un_Oper o WITH(NOLOCK) 
		join Un_Tio TioTIN on TioTIN.iTINOperID = o.operid
		WHERE	(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd )
			OR
				(@bAll = 0 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd )
		UNION

		SELECT 
			o.OperID,
			TioOUT.iTioId
		FROM Un_Oper o WITH(NOLOCK) 
		join Un_Tio TioOUT on TioOUT.iOUTOperID = o.operid
		WHERE	(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd )
			OR
				(@bAll = 0 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd )

	CREATE TABLE #tCESP (
		ConventionID INTEGER PRIMARY KEY,
		fCESG MONEY NOT NULL,
		fACESG MONEY NOT NULL,
		fCLB MONEY NOT NULL,
		fCESG_ACESG_TIN MONEY NOT NULL,
		fCLB_TIN MONEY NOT NULL,
		fCESG_ACESG_OUT MONEY NOT NULL,
		fCLB_OUT MONEY NOT NULL,
		fCESPOfScholarship MONEY NOT NULL,
		fCESG_ACESG_CLB_RIO MONEY NOT NULL,
		fCESG_ACESG_CLB_TRI MONEY NOT NULL,
		fCESG_ACESG_CLB_RIM MONEY NOT NULL,
		fCESG_ACESG_CLB_TIO MONEY NOT NULL,
		fCESG_ACESG_CLB_ARI MONEY NOT NULL)

		-- Subventions(PCEE) par convention
		INSERT INTO #tCESP
		
		select
			ConventionID,
			fCESG = SUM(fCESG),
			fACESG = SUM(fACESG),
			fCLB = SUM(fCLB),
			fCESG_ACESG_TIN = SUM(fCESG_ACESG_TIN),
			fCLB_TIN = SUM(fCLB_TIN),
			fCESG_ACESG_OUT = SUM(fCESG_ACESG_OUT),
			fCLB_OUT = SUM(fCLB_OUT),
			fCESPOfScholarship = SUM(fCESPOfScholarship),
			fCESG_ACESG_CLB_RIO = SUM(fCESG_ACESG_CLB_RIO),
			fCESG_ACESG_CLB_TRI = SUM(fCESG_ACESG_CLB_TRI),
			fCESG_ACESG_CLB_RIM = SUM(fCESG_ACESG_CLB_RIM),
			fCESG_ACESG_CLB_TIO = SUM(fCESG_ACESG_CLB_TIO),
			fCESG_ACESG_CLB_ARI = SUM(fCESG_ACESG_CLB_ARI)
			
			FROM (
		
			SELECT
				CE.ConventionID,
				fCESG = SUM(CASE WHEN O.OperTypeID = 'SUB' THEN CE.fCESG ELSE 0 END),
				fACESG = SUM(CASE WHEN O.OperTypeID = 'SUB' THEN CE.fACESG ELSE 0 END),
				fCLB = SUM(CASE WHEN O.OperTypeID = 'SUB' THEN CE.fCLB ELSE 0 END),
				fCESG_ACESG_TIN = SUM(CASE WHEN O.OperTypeID = 'TIN' THEN CE.fCESG + CE.fACESG ELSE 0 END),
				fCLB_TIN = SUM(CASE WHEN O.OperTypeID = 'TIN' THEN CE.fCLB ELSE 0 END),
				fCESG_ACESG_OUT = SUM(CASE WHEN O.OperTypeID = 'OUT' THEN CE.fCESG + CE.fACESG ELSE 0 END),
				fCLB_OUT = SUM(CASE WHEN O.OperTypeID = 'OUT' THEN CE.fCLB ELSE 0 END),
				fCESPOfScholarship = SUM(CASE WHEN O.OperTypeID = 'PAE' THEN CE.fCESG + CE.fACESG + CE.fCLB ELSE 0 END),
				fCESG_ACESG_CLB_RIO = SUM(CASE WHEN O.OperTypeID = 'RIO' THEN CE.fCESG + CE.fACESG + CE.fCLB ELSE 0 END),
				fCESG_ACESG_CLB_TRI = SUM(CASE WHEN O.OperTypeID = 'TRI' THEN CE.fCESG + CE.fACESG + CE.fCLB ELSE 0 END),
				fCESG_ACESG_CLB_RIM = SUM(CASE WHEN O.OperTypeID = 'RIM' THEN CE.fCESG + CE.fACESG + CE.fCLB ELSE 0 END),
				fCESG_ACESG_CLB_TIO = 0,
				fCESG_ACESG_CLB_ARI = SUM(CASE WHEN O.OperTypeID = 'ARI' THEN CE.fCESG + CE.fACESG + CE.fCLB ELSE 0 END)
			FROM Un_CESP CE
			JOIN Un_Oper O ON O.OperID = CE.OperID
			LEFT JOIN #tOperTIO TIO ON O.OperID = TIO.OperID
			WHERE O.OperTypeID IN ('OUT', 'TIN', 'PAE', 'SUB', 'RIO', 'ARI', 'TRI', 'RIM')
				AND (
					(@bAll = 1 and LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) <= @dtEnd)
					OR
					(@bAll = 0 AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
					)
				AND TIO.OperID IS NULL -- exclure les TIO
			GROUP BY
				CE.ConventionID

			UNION ALL
			
			-- LES TIO
			SELECT
				CE.ConventionID,
				fCESG = 0,
				fACESG = 0,
				fCLB = 0,
				fCESG_ACESG_TIN = 0,
				fCLB_TIN = 0,
				fCESG_ACESG_OUT = 0,
				fCLB_OUT = 0,
				fCESPOfScholarship = 0,
				fCESG_ACESG_CLB_RIO = 0,
				fCESG_ACESG_CLB_TRI = 0,
				fCESG_ACESG_CLB_RIM = 0,
				fCESG_ACESG_CLB_TIO = SUM(CE.fCESG + CE.fACESG + CE.fCLB),
				fCESG_ACESG_CLB_ARI = 0
			FROM Un_CESP CE
			JOIN Un_Oper O ON O.OperID = CE.OperID
			JOIN #tOperTIO TIO ON O.OperID = TIO.OperID
			GROUP BY
				CE.ConventionID
			) Y
			GROUP BY ConventionID
			HAVING 
				SUM(fCESG) <> 0
				OR SUM(fACESG) <> 0
				OR SUM(fCLB) <> 0
				OR SUM(fCESG_ACESG_TIN) <> 0
				OR SUM(fCLB_TIN) <> 0
				OR SUM(fCESG_ACESG_OUT) <> 0
				OR SUM(fCLB_OUT) <> 0
				OR SUM(fCESPOfScholarship) <> 0
				OR SUM(fCESG_ACESG_CLB_RIO) <> 0
				OR SUM(fCESG_ACESG_CLB_TRI) <> 0
				OR SUM(fCESG_ACESG_CLB_RIM) <> 0
				OR SUM(fCESG_ACESG_CLB_TIO) <> 0
				OR SUM(fCESG_ACESG_CLB_ARI) <> 0

	CREATE TABLE #tConventionOper (
		ConventionID INTEGER PRIMARY KEY,
		fINS MONEY NOT NULL,
		fINS_ARI MONEY NOT NULL,
		fCESPInt_TIN MONEY NOT NULL,
		fCESPInt_OUT MONEY NOT NULL,
		fCESPOfScholarship MONEY NOT NULL,
		fCESPInt_PRA MONEY NOT NULL,
		fCESPInt_RIO MONEY NOT NULL,
		fCESPInt_TIO MONEY NOT NULL,
		fCESPInt_TRI MONEY NOT NULL,
		fCESPInt_RIM MONEY NOT NULL)

		INSERT INTO #tConventionOper
			SELECT
				V.ConventionID,
				fINS = SUM(V.fINS),
				fINS_ARI = SUM(fINS_ARI),
				fCESPInt_TIN = SUM(V.fCESPInt_TIN),
				fCESPInt_OUT = SUM(V.fCESPInt_OUT),
				fCESPOfScholarship = SUM(V.fCESPOfScholarship),
				fCESPInt_PRA = SUM(fCESPInt_PRA),
				fCESPInt_RIO = SUM(fCESPInt_RIO),
				fCESPInt_TIO = SUM(fCESPInt_TIO),
				fCESPInt_TRI = SUM(fCESPInt_TRI),
				fCESPInt_RIM = SUM(fCESPInt_RIM)
			FROM (
				SELECT 
					CO.ConventionID,
					fINS = CO.ConventionOperAmount,
					fINS_ARI = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_PRA = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0,
					fCESPInt_TRI = 0,
					fCESPInt_RIM = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') -- Int. TIN
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE (CHARINDEX(Un_Oper.OperTypeID,@vcOPER_RENDEMENT_POSITIF_NEGATIF) > 0)
						AND (
							(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd)
							OR
							(@bAll = 0 AND LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
							)
						)

				---------
				UNION ALL
				---------
					
				SELECT 
					CO.ConventionID,
					fINS = 0,
					fINS_ARI = CO.ConventionOperAmount,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_PRA = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0,
					fCESPInt_TRI = 0,
					fCESPInt_RIM = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST')
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE (Un_Oper.OperTypeID='ARI')
						AND (
							(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd)
							OR
							(@bAll = 0 AND LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
							)
						)						
				---------
				UNION ALL
				---------
				SELECT 
					CO.ConventionID,
					fINS = 0,
					fINS_ARI = 0,
					fCESPInt_TIN = CO.ConventionOperAmount,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_PRA = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0,
					fCESPInt_TRI = 0,
					fCESPInt_RIM = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID = 'IST'
					AND CO.OperID IN (
						SELECT OP.OperID
						FROM Un_Oper OP
						LEFT JOIN #tOperTIO TIO on op.operid = TIO.operid
						WHERE OperTypeID = 'TIN' 
						AND (
							(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd)
							OR
							(@bAll = 0 AND LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
							)
						AND TIO.operid IS NULL
						)
				---------
				UNION ALL
				---------
				SELECT 
					CO.ConventionID,
					fINS = 0,
					fINS_ARI = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = CO.ConventionOperAmount,
					fCESPOfScholarship = 0,
					fCESPInt_PRA = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0,
					fCESPInt_TRI = 0,
					fCESPInt_RIM = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST')
					AND CO.OperID IN (
						SELECT OP.OperID
						FROM Un_Oper op
						LEFT JOIN #tOperTIO tio on op.operid = TIO.operid
						WHERE OperTypeID = 'OUT' 
						AND (
							(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd)
							OR
							(@bAll = 0 AND LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
							)
						AND TIO.operid IS NULL
						)
				---------
				UNION ALL
				---------
				SELECT 
					CO.ConventionID,
					fINS = 0,
					fINS_ARI = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = CO.ConventionOperAmount,
					fCESPInt_PRA = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0,
					fCESPInt_TRI = 0,
					fCESPInt_RIM = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') 
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE OperTypeID = 'PAE' 
						AND (
							(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd)
							OR
							(@bAll = 0 AND LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
							)
						)
				---------
				UNION ALL
				---------
				SELECT 
					CO.ConventionID,
					fINS = 0,
					fINS_ARI = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_PRA = CO.ConventionOperAmount,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0,
					fCESPInt_TRI = 0,
					fCESPInt_RIM = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') 
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE OperTypeID = 'PRA' 
						AND (
							(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd)
							OR
							(@bAll = 0 AND LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
							)
						)
				---------
				UNION ALL
				---------
				SELECT --RIO
					CO.ConventionID,
					fINS = 0,
					fINS_ARI = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_PRA = 0,
					fCESPInt_RIO = CO.ConventionOperAmount,
					fCESPInt_TIO = 0,
					fCESPInt_TRI = 0,
					fCESPInt_RIM = 0

				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST')
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE OperTypeID = 'RIO' 
						AND (
							(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd)
							OR
							(@bAll = 0 AND LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
							)
						)
				---------
				UNION ALL
				---------
				SELECT --TIO
					CO.ConventionID,
					fINS = 0,
					fINS_ARI = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_PRA = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = CO.ConventionOperAmount,
					fCESPInt_TRI = 0,
					fCESPInt_RIM = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') 
					AND CO.OperID IN (
						SELECT OperID
						FROM #tOperTIO
						)

				---------
				UNION ALL
				---------
				SELECT --TRI
					CO.ConventionID,
					fINS = 0,
					fINS_ARI = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_PRA = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0,
					fCESPInt_TRI = CO.ConventionOperAmount,
					fCESPInt_RIM = 0

				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') 
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE OperTypeID = 'TRI'
						AND (
							(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd)
							OR
							(@bAll = 0 AND LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
							)
						)
				---------
				UNION ALL
				---------
				SELECT --RIM
					CO.ConventionID,
					fINS = 0,
					fINS_ARI = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_PRA = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0,
					fCESPInt_TRI = 0,
					fCESPInt_RIM = CO.ConventionOperAmount

				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') 
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE OperTypeID = 'RIM'
						AND (
							(@bAll = 1 and LEFT(CONVERT(VARCHAR, OperDate, 120), 10) <= @dtEnd)
							OR
							(@bAll = 0 AND LEFT(CONVERT(VARCHAR, OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd)
							)
						)

				) V
			GROUP BY V.ConventionID
			HAVING SUM(V.fINS) <> 0 -- Au moins un des montants doit être différent de 0.00$
				OR SUM(V.fINS_ARI) <> 0
				OR SUM(V.fCESPInt_TIN) <> 0
				OR SUM(V.fCESPInt_OUT) <> 0
				OR SUM(V.fCESPOfScholarship) <> 0
				OR SUM(V.fCESPInt_PRA) <> 0
				OR SUM(fCESPInt_RIO) <> 0
				OR SUM(fCESPInt_TIO) <> 0
				OR SUM(fCESPInt_TRI) <> 0
				OR SUM(fCESPInt_RIM) <> 0

/*
		SELECT
			GroupeRegime = RR.vcDescription,
			P.OrderOfPlanInReport,
			P.PlanID, -- ID unique du régime
			PlanDesc = P.NomPlan, -- Description du régime
			YearQualif = ISNULL(Y.YearQualif,C.YearQualif), -- Année de qualification aux bourses de la convention. C'est l'année à laquelle le bénéficiaire de la convention pourra toucher sa première bourse pour cette convention s'il rempli les conditions.
			C.ConventionNo, -- Numéro de convention
			vcSubscriber = S.LastName+', '+S.FirstName, -- Nom, prénom du souscripteur
			fUnitQty = U.UnitQty, -- Nombre d’unité
			fCESG = ISNULL(CESP.fCESG,0), -- SCEE
			fACESG = ISNULL(CESP.fACESG,0), -- SCEE+
			fCLB = ISNULL(CESP.fCLB,0), -- BEC
			fINS = ISNULL(CO.fINS,0), -- Intérêts créditeurs - SCEE
			fINS_ARI = ISNULL(CO.fINS_ARI,0), -- Rendements transférés (ARI)
			fCESG_ACESG_TIN = ISNULL(CESP.fCESG_ACESG_TIN,0), -- SCEE et SCEE+ reçue (TIN)
			fCLB_TIN = ISNULL(CESP.fCLB_TIN,0), -- BEC reçu (TIN)
			fCESG_ACESG_OUT = ISNULL(CESP.fCESG_ACESG_OUT,0), -- SCEE et SCEE+ payée (OUT)
			fCLB_OUT = ISNULL(CESP.fCLB_OUT,0), -- BEC payé (OUT)
			fCESPInt_TIN = ISNULL(CO.fCESPInt_TIN,0), -- Intérêts PCEE TIN reçus
			fCESPInt_OUT = ISNULL(CO.fCESPInt_OUT,0), -- Intérêts SCEE, intérêts SCEE+, intérêts BEC et intérêts payés (OUT)
			fCESPOfScholarship = ISNULL(CESP.fCESPOfScholarship,0)+ISNULL(CO.fCESPOfScholarship,0), -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
			fCESPInt_PRA = ISNULL(CO.fCESPInt_PRA,0), -- Intérêts SCEE, SCEE+ et BEC (RIO)
			fCESG_ACESG_CLB_RIO = ISNULL(CESP.fCESG_ACESG_CLB_RIO,0), -- SCEE, SCEE+ et BEC (RIO)
			fCESPInt_RIO = ISNULL(CO.fCESPInt_RIO,0), -- Intérêts SCEE, SCEE+ et BEC (RIO)
			fCESG_ACESG_CLB_TIO = ISNULL(CESP.fCESG_ACESG_CLB_TIO,0), -- SCEE, SCEE+ et BEC (TIO)
			fCESPInt_TIO = ISNULL(CO.fCESPInt_TIO,0), -- Intérêts SCEE, SCEE+ et BEC (TIO)
			
			fCESG_ACESG_CLB_TRI = ISNULL(CESP.fCESG_ACESG_CLB_TRI,0), -- SCEE, SCEE+ et BEC (TRI)
			fCESPInt_TRI = ISNULL(CO.fCESPInt_TRI,0), -- Intérêts SCEE, SCEE+ et BEC (TRI)
			fCESG_ACESG_CLB_RIM = ISNULL(CESP.fCESG_ACESG_CLB_RIM,0), -- SCEE, SCEE+ et BEC (RIM)
			fCESPInt_RIM = ISNULL(CO.fCESPInt_RIM,0), -- Intérêts SCEE, SCEE+ et BEC (RIM)
			
			fCESG_ACESG_CLB_ARI = ISNULL(fCESG_ACESG_CLB_ARI,0), -- Subventions transférés (ARI)
			SoldeNetGarantie =	
				ISNULL(CESP.fCESG,0) + 
				ISNULL(CESP.fACESG,0) + 
				ISNULL(CESP.fCLB,0) + 
				ISNULL(CESP.fCLB_TIN,0) + -- BEC reçu (TIN)
				ISNULL(CESP.fCLB_OUT,0) + -- BEC payé (OUT)
				ISNULL(CESP.fCESG_ACESG_TIN,0) + 
				ISNULL(CESP.fCESG_ACESG_OUT,0) + 
				ISNULL(CESP.fCESPOfScholarship,0) + 
				ISNULL(CESP.fCESG_ACESG_CLB_RIO,0) + 
				ISNULL(CESP.fCESG_ACESG_CLB_TIO,0) +
				ISNULL(CESP.fCESG_ACESG_CLB_TRI,0) + 
				ISNULL(CESP.fCESG_ACESG_CLB_RIM,0) + 
				ISNULL(fCESG_ACESG_CLB_ARI,0),
			SoldeNetRendement = 
				ISNULL(CO.fINS,0) + 
				ISNULL(CO.fINS_ARI,0) + 
				ISNULL(CO.fCESPInt_TIN,0) + 
				ISNULL(CO.fCESPInt_OUT,0) + 
				ISNULL(CO.fCESPOfScholarship,0) + 
				ISNULL(CO.fCESPInt_PRA,0) +
				ISNULL(CO.fCESPInt_RIO,0) + 
				ISNULL(CO.fCESPInt_TIO,0) +
				ISNULL(CO.fCESPInt_TRI,0) +
				ISNULL(CO.fCESPInt_RIM,0),
			fTotal = 
				ISNULL(CESP.fCESG,0) + -- SCEE
				ISNULL(CESP.fACESG,0) + -- SCEE+
				ISNULL(CESP.fCLB,0) + -- BEC
				ISNULL(CO.fINS,0) + -- Intérêts créditeurs - SCEE
				ISNULL(CO.fINS_ARI,0) + 
				ISNULL(CESP.fCESG_ACESG_TIN,0) + -- SCEE et SCEE+ reçue (TIN)
				ISNULL(CESP.fCLB_TIN,0) + -- BEC reçu (TIN)
				ISNULL(CESP.fCESG_ACESG_OUT,0) + -- SCEE et SCEE+ payée (OUT)
				ISNULL(CESP.fCLB_OUT,0) + -- BEC payé (OUT)
				ISNULL(CO.fCESPInt_TIN,0) + -- Intérêts PCEE TIN reçus
				ISNULL(CO.fCESPInt_OUT,0) + -- Intérêts SCEE, intérêts SCEE+, intérêts BEC et intérêts payés (OUT)
				ISNULL(CESP.fCESG_ACESG_CLB_RIO,0) + -- SCEE, SCEE+ et BEC (RIO)
				ISNULL(CO.fCESPInt_RIO,0) +  -- Intérêts SCEE, SCEE+ et BEC (RIO)
				ISNULL(CO.fCESPInt_PRA,0) +

				ISNULL(CO.fCESPInt_TRI,0) +
				ISNULL(CESP.fCESG_ACESG_CLB_TRI,0) +
				ISNULL(CO.fCESPInt_RIM,0) +
				ISNULL(CESP.fCESG_ACESG_CLB_RIM,0) +
				
				ISNULL(CESP.fCESG_ACESG_CLB_TIO,0) + -- SCEE, SCEE+ et BEC (TIO)
				ISNULL(CO.fCESPInt_TIO,0) +  -- Intérêts SCEE, SCEE+ et BEC (TIO)
				ISNULL(fCESG_ACESG_CLB_ARI,0) +
				ISNULL(CESP.fCESPOfScholarship,0)+ISNULL(CO.fCESPOfScholarship,0) -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
		FROM #tConventionState CS
		JOIN dbo.Un_Convention C ON CS.ConventionID = C.ConventionID
		JOIN Un_Plan P ON C.PlanID = P.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON P.iID_Regroupement_Regime = RR.iID_Regroupement_Regime
		LEFT JOIN Un_ConventionYearQualif Y ON Y.ConventionID = C.ConventionID AND @dtEnd BETWEEN Y.EffectDate AND ISNULL(Y.TerminatedDate,@dtEnd+1)
		JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
		LEFT JOIN ( -- GLPI 3157 faire un LEFT JOIN plutot qu'un JOIN
			SELECT
				CS.ConventionID,
				UnitQty = SUM(U.UnitQty+ISNULL(UR.UnitQty, 0))
			FROM #tConventionState CS
			JOIN dbo.Un_Unit U ON U.ConventionID = CS.ConventionID
			LEFT JOIN (
				-- Va chercher les unités résiliés après la date de fin de la période. Il faut additionner ces unités à ceux actuel des
				-- groupes d'unités pour connaître le nombre d'unités à la date de fin de période
		 		SELECT
					UnitID,
					UnitQty = SUM(UnitQty)
				FROM Un_UnitReduction
				WHERE ReductionDate > @dtEnd -- Résiliation d'unités faites après la date de fin de période.
				GROUP BY UnitID
				) UR ON UR.UnitID = U.UnitID
			--WHERE U.dtFirstDeposit <= @dtEnd -- GLPI 3157 dtFirstDeposit peut être null dans le cas d'un RIO -- Et cette clause ne sert à rien selon PLS
			GROUP BY CS.ConventionID
			) U ON U.ConventionID = C.ConventionID
		LEFT JOIN #tCESP CESP ON CESP.ConventionID = C.ConventionID
		LEFT JOIN #tConventionOper CO ON CO.ConventionID = C.ConventionID
		WHERE ( CESP.ConventionID IS NOT NULL
				OR CO.ConventionID IS NOT NULL
				)

			--	RETURN

*/
	SELECT
		PlanID, -- ID unique du régime
		PlanDesc, -- Description du régime
		GroupeRegime,
		YearQualif, -- Année de qualification
		iConventionCount = COUNT(ConventionNo), -- Nombre de convention
		fUnitQty = SUM(fUnitQty), -- Nombre d’unité
		fCESG = SUM(fCESG), -- SCEE
		fACESG = SUM(fACESG), -- SCEE+
		fCLB = SUM(fCLB), -- BEC
		fINS = SUM(fINS), -- Intérêts créditeurs - SCEE
		fINS_ARI = SUM(fINS_ARI), --Rendements transférés (ARI)
		fCESG_ACESG_TIN = SUM(fCESG_ACESG_TIN), -- SCEE et SCEE+ reçue (TIN)
		fCLB_TIN = SUM(fCLB_TIN), -- BEC reçu (TIN)
		fCESG_ACESG_OUT = SUM(fCESG_ACESG_OUT), -- SCEE et SCEE+ payée (OUT)
		fCLB_OUT = SUM(fCLB_OUT), -- BEC payé (OUT)
		fCESPInt_TIN = SUM(fCESPInt_TIN), -- Intérêts PCEE TIN reçus
		fCESPInt_OUT = SUM(fCESPInt_OUT), -- Intérêts SCEE, intérêts SCEE+, intérêts BEC et intérêts payés (OUT)
		fCESPOfScholarship = SUM(fCESPOfScholarship), -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
		fCESPInt_PRA = SUM(fCESPInt_PRA),-- Intérêts SCEE, SCEE+ et BEC (PRA)
		fCESG_ACESG_CLB_RIO = SUM(fCESG_ACESG_CLB_RIO), -- SCEE, SCEE+ et BEC (RIO)
		fCESPInt_RIO = SUM(fCESPInt_RIO), -- Intérêts SCEE, SCEE+ et BEC (RIO)
		fCESG_ACESG_CLB_TIO = SUM(fCESG_ACESG_CLB_TIO), -- SCEE, SCEE+ et BEC (TIO)
		fCESPInt_TIO = SUM(fCESPInt_TIO), -- Intérêts SCEE, SCEE+ et BEC (TIO)
		
		fCESG_ACESG_CLB_TRI = SUM(fCESG_ACESG_CLB_TRI), -- SCEE, SCEE+ et BEC (TRI)
		fCESPInt_TRI = SUM(fCESPInt_TRI), -- Intérêts SCEE, SCEE+ et BEC (TRI)
		fCESG_ACESG_CLB_RIM = SUM(fCESG_ACESG_CLB_RIM), -- SCEE, SCEE+ et BEC (RIM)
		fCESPInt_RIM = SUM(fCESPInt_RIM), -- Intérêts SCEE, SCEE+ et BEC (RIM)
		
		fCESG_ACESG_CLB_ARI = SUM(fCESG_ACESG_CLB_ARI), -- Subvention transférés (ARI)
		SoldeNetGarantie = SUM(SoldeNetGarantie),
		SoldeNetRendement = SUM(SoldeNetRendement),
		fTotal = SUM(fTotal) -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
	FROM (
		SELECT
			GroupeRegime = RR.vcDescription,
			P.OrderOfPlanInReport,
			P.PlanID, -- ID unique du régime
			PlanDesc = P.NomPlan, -- Description du régime
			YearQualif = ISNULL(Y.YearQualif,C.YearQualif), -- Année de qualification aux bourses de la convention. C'est l'année à laquelle le bénéficiaire de la convention pourra toucher sa première bourse pour cette convention s'il rempli les conditions.
			C.ConventionNo, -- Numéro de convention
			vcSubscriber = S.LastName+', '+S.FirstName, -- Nom, prénom du souscripteur
			fUnitQty = U.UnitQty, -- Nombre d’unité
			fCESG = ISNULL(CESP.fCESG,0), -- SCEE
			fACESG = ISNULL(CESP.fACESG,0), -- SCEE+
			fCLB = ISNULL(CESP.fCLB,0), -- BEC
			fINS = ISNULL(CO.fINS,0), -- Intérêts créditeurs - SCEE
			fINS_ARI = ISNULL(CO.fINS_ARI,0), -- Rendements transférés (ARI)
			fCESG_ACESG_TIN = ISNULL(CESP.fCESG_ACESG_TIN,0), -- SCEE et SCEE+ reçue (TIN)
			fCLB_TIN = ISNULL(CESP.fCLB_TIN,0), -- BEC reçu (TIN)
			fCESG_ACESG_OUT = ISNULL(CESP.fCESG_ACESG_OUT,0), -- SCEE et SCEE+ payée (OUT)
			fCLB_OUT = ISNULL(CESP.fCLB_OUT,0), -- BEC payé (OUT)
			fCESPInt_TIN = ISNULL(CO.fCESPInt_TIN,0), -- Intérêts PCEE TIN reçus
			fCESPInt_OUT = ISNULL(CO.fCESPInt_OUT,0), -- Intérêts SCEE, intérêts SCEE+, intérêts BEC et intérêts payés (OUT)
			fCESPOfScholarship = ISNULL(CESP.fCESPOfScholarship,0)+ISNULL(CO.fCESPOfScholarship,0), -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
			fCESPInt_PRA = ISNULL(CO.fCESPInt_PRA,0), -- Intérêts SCEE, SCEE+ et BEC (RIO)
			fCESG_ACESG_CLB_RIO = ISNULL(CESP.fCESG_ACESG_CLB_RIO,0), -- SCEE, SCEE+ et BEC (RIO)
			fCESPInt_RIO = ISNULL(CO.fCESPInt_RIO,0), -- Intérêts SCEE, SCEE+ et BEC (RIO)
			fCESG_ACESG_CLB_TIO = ISNULL(CESP.fCESG_ACESG_CLB_TIO,0), -- SCEE, SCEE+ et BEC (TIO)
			fCESPInt_TIO = ISNULL(CO.fCESPInt_TIO,0), -- Intérêts SCEE, SCEE+ et BEC (TIO)
			
			fCESG_ACESG_CLB_TRI = ISNULL(CESP.fCESG_ACESG_CLB_TRI,0), -- SCEE, SCEE+ et BEC (TRI)
			fCESPInt_TRI = ISNULL(CO.fCESPInt_TRI,0), -- Intérêts SCEE, SCEE+ et BEC (TRI)
			fCESG_ACESG_CLB_RIM = ISNULL(CESP.fCESG_ACESG_CLB_RIM,0), -- SCEE, SCEE+ et BEC (RIM)
			fCESPInt_RIM = ISNULL(CO.fCESPInt_RIM,0), -- Intérêts SCEE, SCEE+ et BEC (RIM)
			
			fCESG_ACESG_CLB_ARI = ISNULL(fCESG_ACESG_CLB_ARI,0), -- Subventions transférés (ARI)
			SoldeNetGarantie =	
				ISNULL(CESP.fCESG,0) + 
				ISNULL(CESP.fACESG,0) + 
				ISNULL(CESP.fCLB,0) + 
				ISNULL(CESP.fCLB_TIN,0) + -- BEC reçu (TIN)
				ISNULL(CESP.fCLB_OUT,0) + -- BEC payé (OUT)
				ISNULL(CESP.fCESG_ACESG_TIN,0) + 
				ISNULL(CESP.fCESG_ACESG_OUT,0) + 
				ISNULL(CESP.fCESPOfScholarship,0) + 
				ISNULL(CESP.fCESG_ACESG_CLB_RIO,0) + 
				ISNULL(CESP.fCESG_ACESG_CLB_TIO,0) +
				ISNULL(CESP.fCESG_ACESG_CLB_TRI,0) + 
				ISNULL(CESP.fCESG_ACESG_CLB_RIM,0) + 
				ISNULL(fCESG_ACESG_CLB_ARI,0),
			SoldeNetRendement = 
				ISNULL(CO.fINS,0) + 
				ISNULL(CO.fINS_ARI,0) + 
				ISNULL(CO.fCESPInt_TIN,0) + 
				ISNULL(CO.fCESPInt_OUT,0) + 
				ISNULL(CO.fCESPOfScholarship,0) + 
				ISNULL(CO.fCESPInt_PRA,0) +
				ISNULL(CO.fCESPInt_RIO,0) + 
				ISNULL(CO.fCESPInt_TIO,0) +
				ISNULL(CO.fCESPInt_TRI,0) +
				ISNULL(CO.fCESPInt_RIM,0),
			fTotal = 
				ISNULL(CESP.fCESG,0) + -- SCEE
				ISNULL(CESP.fACESG,0) + -- SCEE+
				ISNULL(CESP.fCLB,0) + -- BEC
				ISNULL(CO.fINS,0) + -- Intérêts créditeurs - SCEE
				ISNULL(CO.fINS_ARI,0) + 
				ISNULL(CESP.fCESG_ACESG_TIN,0) + -- SCEE et SCEE+ reçue (TIN)
				ISNULL(CESP.fCLB_TIN,0) + -- BEC reçu (TIN)
				ISNULL(CESP.fCESG_ACESG_OUT,0) + -- SCEE et SCEE+ payée (OUT)
				ISNULL(CESP.fCLB_OUT,0) + -- BEC payé (OUT)
				ISNULL(CO.fCESPInt_TIN,0) + -- Intérêts PCEE TIN reçus
				ISNULL(CO.fCESPInt_OUT,0) + -- Intérêts SCEE, intérêts SCEE+, intérêts BEC et intérêts payés (OUT)
				ISNULL(CESP.fCESG_ACESG_CLB_RIO,0) + -- SCEE, SCEE+ et BEC (RIO)
				ISNULL(CO.fCESPInt_RIO,0) +  -- Intérêts SCEE, SCEE+ et BEC (RIO)
				ISNULL(CO.fCESPInt_PRA,0) +

				ISNULL(CO.fCESPInt_TRI,0) +
				ISNULL(CESP.fCESG_ACESG_CLB_TRI,0) +
				ISNULL(CO.fCESPInt_RIM,0) +
				ISNULL(CESP.fCESG_ACESG_CLB_RIM,0) +
				
				ISNULL(CESP.fCESG_ACESG_CLB_TIO,0) + -- SCEE, SCEE+ et BEC (TIO)
				ISNULL(CO.fCESPInt_TIO,0) +  -- Intérêts SCEE, SCEE+ et BEC (TIO)
				ISNULL(fCESG_ACESG_CLB_ARI,0) +
				ISNULL(CESP.fCESPOfScholarship,0)+ISNULL(CO.fCESPOfScholarship,0) -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
		FROM #tConventionState CS
		JOIN dbo.Un_Convention C ON CS.ConventionID = C.ConventionID
		JOIN Un_Plan P ON C.PlanID = P.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON P.iID_Regroupement_Regime = RR.iID_Regroupement_Regime
		LEFT JOIN Un_ConventionYearQualif Y ON Y.ConventionID = C.ConventionID AND @dtEnd BETWEEN Y.EffectDate AND ISNULL(Y.TerminatedDate,@dtEnd+1)
		JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
		LEFT JOIN ( -- GLPI 3157 faire un LEFT JOIN plutot qu'un JOIN
			SELECT
				CS.ConventionID,
				UnitQty = SUM(U.UnitQty+ISNULL(UR.UnitQty, 0))
			FROM #tConventionState CS
			JOIN dbo.Un_Unit U ON U.ConventionID = CS.ConventionID
			LEFT JOIN (
				-- Va chercher les unités résiliés après la date de fin de la période. Il faut additionner ces unités à ceux actuel des
				-- groupes d'unités pour connaître le nombre d'unités à la date de fin de période
		 		SELECT
					UnitID,
					UnitQty = SUM(UnitQty)
				FROM Un_UnitReduction
				WHERE ReductionDate > @dtEnd -- Résiliation d'unités faites après la date de fin de période.
				GROUP BY UnitID
				) UR ON UR.UnitID = U.UnitID
			--WHERE U.dtFirstDeposit <= @dtEnd -- GLPI 3157 dtFirstDeposit peut être null dans le cas d'un RIO -- Et cette clause ne sert à rien selon PLS
			GROUP BY CS.ConventionID
			) U ON U.ConventionID = C.ConventionID
		LEFT JOIN #tCESP CESP ON CESP.ConventionID = C.ConventionID
		LEFT JOIN #tConventionOper CO ON CO.ConventionID = C.ConventionID
		WHERE ( CESP.ConventionID IS NOT NULL
				OR CO.ConventionID IS NOT NULL
				)
		) V
	GROUP BY
		PlanID, -- ID unique du régime
		PlanDesc, -- Description du régime
		GroupeRegime,
		YearQualif, -- Année de qualification
		OrderOfPlanInReport
	HAVING @iColumnFilter = 0
		OR	( @iColumnFilter = 1 -- 1 = SCEE
			AND SUM(fCESG) <> 0
			)
		OR ( @iColumnFilter = 2 -- 2 = SCEE+
			AND SUM(fACESG) <> 0
			)
		OR ( @iColumnFilter = 3 -- 3 = BEC
			AND SUM(fCLB) <> 0
			)
		OR ( @iColumnFilter = 4 -- 4 = Intérêts créditeurs - SCEE
			AND SUM(fINS) <> 0
			)
		OR ( @iColumnFilter = 5 -- 5 = SCEE et SCEE+ reçu (TIN)
			AND SUM(fCESG_ACESG_TIN) <> 0
			)
		OR ( @iColumnFilter = 6 -- 6 = BEC reçu (TIN)
			AND SUM(fCLB_TIN) <> 0
			)
		OR ( @iColumnFilter = 7 -- 7 = SCEE et SCEE+ payée (OUT)
			AND SUM(fCESG_ACESG_OUT) <> 0
			)
		OR ( @iColumnFilter = 8 -- 8 = BEC payé (OUT)
			AND SUM(fCLB_OUT) <> 0
			)
		OR ( @iColumnFilter = 9 -- 9 = Intérêts SCEE, SCEE+ et BEC reçus (TIN)
			AND SUM(fCESPInt_TIN) <> 0
			)
		OR ( @iColumnFilter = 10 -- 10 = Intérêts SCEE, SCEE+ et BEC payés (OUT)
			AND SUM(fCESPInt_OUT) <> 0
			)
		OR ( @iColumnFilter = 11 -- 11 = SCEE, SCEE+, BEC et Intérêts versés en bourse.
			AND SUM(fCESPOfScholarship) <> 0
			)
		OR ( @iColumnFilter = 12 -- 12 = Rendements transférés (ARI)
			AND SUM(fINS_ARI) <> 0
			)
		OR ( @iColumnFilter = 13 -- 13 = Subventions transférés (ARI)
			AND SUM(fCESG_ACESG_CLB_ARI) <> 0
			)

		OR ( @iColumnFilter = 14 -- 14 = Subvention ou rendements (RIO)
			AND (SUM(fCESG_ACESG_CLB_RIO) <> 0  OR SUM(fCESPInt_RIO) <> 0)
			)
			
		OR ( @iColumnFilter = 15 -- 15 = Subvention ou rendement (TRI)
			AND (SUM(fCESG_ACESG_CLB_TRI) <> 0  OR SUM(fCESPInt_TRI) <> 0)
			)

		OR ( @iColumnFilter = 16 -- 16 = Subvention ou rendement (RIM)
			AND (SUM(fCESG_ACESG_CLB_RIM) <> 0  OR SUM(fCESPInt_RIM) <> 0)
			)
		OR ( @iColumnFilter = 17 -- 16 = rendement (PRA)
			AND (SUM(fCESPInt_PRA) <> 0)
			)			
	ORDER BY
		OrderOfPlanInReport,
		YearQualif


END