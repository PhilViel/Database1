/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportEAFB
Nom du service		: Rapport des EAFB
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportEAFB '1950-01-01','2012-12-31', 'REETRA', NULL, NULL, 4

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-05-25		Donald Huppé						Création du service			
		2011-08-09		Donald Huppé						Enlever les heures dans operdate dans le where, et ailleurs		
		2013-02-25		Donald Huppé						glpi 9201 : ajout des rendement transféré RIO et quelques autres détails
		
															Rend TIN Reçu :	Inclure dans cette colonne les rendements TIN inclus dans une transaction CHQ 
															(ce sont des cas isolés où du rendement TIN a été déposé par une opération CHQ par erreur)									
															(représente 6 270,08$ cumulativement) ITR						
																									
															Rend RIN payé PAE :	Inclure dans cette colonne les rend cotisation inclus dans une transaction RIN 
															(ce sont des cas isolés où on a éliminé du rend sur cotisation car la règle du minimum de 200$ n'était pas respectée - règle abolie par la suite)									
															(représente 129,69$ cumulativement)	INM						
																									
															Rend (transf) RIO :	Ajouter cette colonne au rapport et y inclure les rend TIN et rend RI  et rend ind inclus dans les transactions RIO	(ITR	INM)

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportEAFB] 
(
	@dtDateDe datetime
	,@dtDateA datetime
	,@cReportFilter VARCHAR(20) = 'REE,TRA' -- Filtre sur les états de conventions :
									-- 	REE,TRA = REEE et Transitoire
									-- 	REE = REEE
									--	TRA = Transitoire
									--  FRM = Fermé
	,@cConventionno varchar(15) = NULL -- Filtre optionnel sur un numéro de convention
	,@iYearQualif INT = NULL --Filtre optionnel sur une année de qualification
	,@iPlanID varchar(75) = 0 -- Filtre optionnel sur un plan
)
AS
BEGIN

	IF @cReportFilter <> 'TRA' AND @cReportFilter <> 'FRM'
		SET @cReportFilter = @cReportFilter + 'PRP,FRM'

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
				FROM Un_ConventionConventionState S (READUNCOMMITTED)
				JOIN dbo.Un_Convention C (READUNCOMMITTED) ON C.ConventionID = S.ConventionID
				LEFT JOIN Un_ConventionYearQualif Y (READUNCOMMITTED) ON Y.ConventionID = C.ConventionID AND @dtDateA BETWEEN LEFT(CONVERT(VARCHAR, Y.EffectDate, 120), 10) AND ISNULL(Y.TerminatedDate,@dtDateA+1)
				WHERE 
					LEFT(CONVERT(VARCHAR, S.StartDate, 120), 10) <= @dtDateA -- État à la date de fin de la période
					AND (@cConventionno IS NULL OR C.ConventionNO = @cConventionno)
					AND (@iYearQualif  IS NULL OR ISNULL(Y.YearQualif,C.YearQualif) = @iYearQualif)
					AND (@iPlanID = 0 OR C.PlanID = @iPlanID) 
				GROUP BY S.ConventionID
				) T
			JOIN Un_ConventionConventionState CCS (READUNCOMMITTED) ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
			GROUP BY T.ConventionID
			) V
		JOIN Un_ConventionConventionState CCS (READUNCOMMITTED) ON V.ConventionConventionStateID = CCS.ConventionConventionStateID
		WHERE CHARINDEX(CCS.ConventionStateID, @cReportFilter) > 0 -- L'état doit être un de ceux sélectionné dans le filtre

	select

		Regime,
		GrRegime,
		OrderOfPlanInReport,
		PlanTypeID,
		YearQualif,
		Conventionno,
		unitqty,
		RendAllTINRecu,
		RendIndCotCalc,
		RendCollRINCalc,
		RendAllTINCalc,
		RendAllTINOutPaye,
		RendIndCotOutPaye,
		RendCollCotOutPaye,
		RendAllTINPAEPaye,
		RendIndCotPAEPaye,
		RendCollRINPAEPaye,
		RendAllTINTIO,
		RendRefIndCotTRI,
		RendRefIndCotRIM,
		RendCotRIO,
		AjustAllRendARI,
		
		Total = RendAllTINRecu +
				RendIndCotCalc +
				RendCollRINCalc +
				RendAllTINCalc +
				RendAllTINOutPaye +
				RendIndCotOutPaye +
				RendCollCotOutPaye +
				RendAllTINPAEPaye +
				RendIndCotPAEPaye +
				RendCollRINPAEPaye +
				RendAllTINTIO +
				RendRefIndCotTRI +
				RendRefIndCotRIM +
				RendCotRIO +
				AjustAllRendARI
		
	FROM (
		SELECT 
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,
			P.PlanTypeID,
			YearQualif = ISNULL(Y.YearQualif,C.YearQualif),
			C.Conventionno,
			u2.unitqty,

			-- s'assurer qu'il faut exclure les TIO partout sauf dans les TIO.

			RendAllTINRecu = SUM(CASE WHEN 
									O.OperTypeID IN ('TIN','CHQ') --Ici, CHQ est une exception (voir glpi 9201)
									AND  OP.ConventionOperTypeID = 'ITR' 
									AND  TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),
									
			RendIndCotCalc = SUM(CASE WHEN 
									P.PlanTypeID = 'IND' 
									AND O.OperTypeID IN ('IN+','IN-') 
									AND ISNULL(OR1.vcCode_Raison,'') NOT IN ( 'TRI','RIM') 
									AND OP.ConventionOperTypeID = 'INM' 
									AND TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),
									
			RendCollRINCalc = SUM(CASE WHEN 
									P.PlanTypeID = 'COL' 
									AND O.OperTypeID IN ('IN+','IN-') 
									AND ISNULL(OR1.vcCode_Raison,'') NOT IN ( 'TRI','RIM') 
									AND OP.ConventionOperTypeID = 'INM' 
									AND TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),
									
			RendAllTINCalc = SUM(CASE WHEN 
									O.OperTypeID IN ('IN+','IN-')  
									AND ISNULL(OR1.vcCode_Raison,'') NOT IN ( 'TRI','RIM') 
									AND OP.ConventionOperTypeID = 'ITR' 
									AND TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),
									
			RendAllTINOutPaye = SUM(CASE WHEN 
									O.OperTypeID IN ('OUT') 
									AND OP.ConventionOperTypeID = 'ITR' 
									AND TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),
									
			RendIndCotOutPaye = SUM(CASE WHEN 
									P.PlanTypeID = 'IND' 
									AND O.OperTypeID IN ('OUT') 
									AND OP.ConventionOperTypeID = 'INM' 
									AND TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),
									
			RendCollCotOutPaye = SUM(CASE WHEN 
									P.PlanTypeID = 'COL' 
									AND O.OperTypeID IN ('OUT') 
									AND OP.ConventionOperTypeID = 'INM' 
									AND TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),
									
			RendAllTINPAEPaye = SUM(CASE WHEN 
									O.OperTypeID IN ('PAE') 
									AND OP.ConventionOperTypeID = 'ITR' 
									AND TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),
									
			RendIndCotPAEPaye = SUM(CASE WHEN 
									P.PlanTypeID = 'IND' 
									AND O.OperTypeID IN ('PAE','RIN')  -- Ici RIN est un exception. voir glpi 9201
									AND OP.ConventionOperTypeID = 'INM' 
									AND OR1.vcCode_Raison IS NULL
									AND TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),
									
			RendCollRINPAEPaye = SUM(CASE WHEN 
									P.PlanTypeID = 'COL' 
									AND O.OperTypeID IN ('PAE','RIN') 
									AND OP.ConventionOperTypeID = 'INM' 
									AND OR1.vcCode_Raison IS NULL
									AND TIO.OperID IS NULL
									THEN OP.ConventionOperAmount ELSE 0 END),

			RendAllTINTIO = SUM(CASE WHEN 
									TIO.OperID IS NOT NULL 
									AND OP.ConventionOperTypeID IN ('ITR','INM') 
									THEN OP.ConventionOperAmount ELSE 0 END),

			RendRefIndCotTRI = SUM(CASE WHEN	
									( -- cas original
									O.OperTypeID IN ('IN+') 
									AND OP.ConventionOperTypeID IN ('INM') 
									AND ISNULL(OR1.vcCode_Raison,'') = 'TRI' 
									AND TIO.OperID IS NULL
									)
									OR
									( -- cas du glpi 9201
									 O.OperTypeID = 'TRI' 
									 AND OP.ConventionOperTypeID IN ('INM','ITR') 
									 AND TIO.OperID IS NULL
									)
								
									THEN OP.ConventionOperAmount ELSE 0 END),
			
			RendRefIndCotRIM = SUM(CASE WHEN	
									(-- cas original
									O.OperTypeID IN ('IN+') 
									AND OP.ConventionOperTypeID IN ('INM') 
									AND ISNULL(OR1.vcCode_Raison,'') = 'RIM' 
									AND TIO.OperID is null
									) 
									OR
									(-- cas du glpi 9201
									O.OperTypeID = 'RIM' 
									AND OP.ConventionOperTypeID IN ('INM','ITR') 
									AND TIO.OperID is null
									)
									THEN OP.ConventionOperAmount ELSE 0 END),
			
			RendCotRIO = SUM(CASE WHEN O.OperTypeID = 'RIO' AND OP.ConventionOperTypeID IN ('INM','ITR') AND TIO.OperID IS NULL THEN OP.ConventionOperAmount ELSE 0 END),
			
			AjustAllRendARI = SUM(CASE WHEN O.OperTypeID IN ('ARI') AND OP.ConventionOperTypeID IN ('INM', 'ITR') AND TIO.OperID IS NULL THEN OP.ConventionOperAmount ELSE 0 END)
			
		FROM 
			Un_Oper O
			JOIN Un_ConventionOper OP ON O.OperID = OP.OperID
			JOIN dbo.Un_Convention C ON op.ConventionID = C.ConventionID
			JOIN #tConventionState CS on CS.ConventionID = C.ConventionID
			JOIN Un_Plan P ON C.PlanID = P.PlanID
			JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
			
			LEFT JOIN	(
						SELECT DISTINCT iID_Operation_Parent, iID_Operation_Enfant, iID_Raison_Association 
						FROM tblOPER_AssociationOperations
						) OA ON OA.iID_Operation_Enfant = O.OperID

			LEFT JOIN tblOPER_RaisonsAssociation OR1 ON OA.iID_Raison_Association = OR1.iID_Raison_Association
			
			LEFT JOIN Un_ConventionYearQualif Y (READUNCOMMITTED) ON Y.ConventionID = C.ConventionID AND @dtDateA BETWEEN Y.EffectDate AND ISNULL(Y.TerminatedDate,@dtDateA+1)
			
			LEFT JOIN	(
						SELECT conventionid, UnitQty = SUM(u.unitqty + ISNULL(ur.unitqtyRes,0))
						FROM dbo.Un_Unit u
						LEFT JOIN (	
								SELECT unitid, unitqtyRes = SUM(UnitQty) 
								FROM Un_UnitReduction 
								WHERE ReductionDate >= @dtDateA 
								GROUP BY unitid
								) ur ON U.unitid = ur.UnitID
						GROUP by conventionid
						) u2 on c.conventionid = u2.conventionid

			LEFT JOIN ( -- Les TIO
						SELECT 
							OPER1.OperID,
							TioTIN.iTioId
						FROM Un_Oper OPER1
						join Un_Tio TioTIN ON TioTIN.iTINOperID = OPER1.operid
						UNION
						SELECT 
							OPER2.OperID,
							TioOUT.iTioId
						FROM Un_Oper OPER2
						JOIN Un_Tio TioOUT ON TioOUT.iOUTOperID = OPER2.operid
				)TIO ON O.OperID = TIO.OperID
		WHERE
			LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtDateDe AND @dtDateA
			AND O.OperTypeID IN ('TIN','IN+','IN-','OUT','PAE','TIO','TRI','RIM','RIO','ARI','RIN','CHQ')
			AND OP.ConventionOperTypeID IN ('ITR','INM')
		GROUP BY
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport,
			P.PlanTypeID,
			ISNULL(Y.YearQualif,C.YearQualif),
			C.Conventionno,
			u2.unitqty
		) V
END


