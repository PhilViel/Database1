/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_UnitCommVsDep
Description         :	Procédure retournant l’historique des dépôts versus commissions pour un groupe d’unités.
Valeurs de retours  :	Dataset :
									UnitCommVsDepID	INTEGER			ID unique de l’enregistrement d’historique.
									UnitID				INTEGER			ID du groupe d’unités.
									Type					CHAR(3)			DEP = somme de dépôts, COM = commissions et EXT =
																				exceptions
									dtDate				DATETIME			Date du traitement pour type DEP et COM et date de
																				l’exception pour EXT.
									Fee					MONEY				Frais déposé.
									BenefInsur			MONEY				Assurance bénéficiaire déposé.
									SubscInsur			MONEY				Assurance souscripteur déposé.
									Advance				MONEY				Avances sur commissions versées.
									CoveredAdvance		MONEY				Avances sur commissions couvertes.
									Comm					MONEY				Commissions de services versées.
									Bonus					MONEY				Bonis d’affaires versées.
									RepLevelAndRole	VARCHAR(150)	Rôle et niveau du représentant.
									RepPct				MONEY				Pourcentage de commissions versées à ce représentant.
									RepName				VARCHAR(87)		Nom, prénom du représentant.
Note                :	ADX0000723	IA	2005-07-13	Bruno Lapointe			Création
										2008-10-29	Pierre-Luc Simard		Correction dans le ORDER BY
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_UnitCommVsDep] (
	@UnitID INTEGER ) -- ID du type d’exception de commissions, 0 = Tous.
AS
BEGIN
	CREATE TABLE #tUnitCommVsDep (
		UnitCommVsDepID INTEGER	IDENTITY, -- ID unique de l’enregistrement d’historique.
		UnitID INTEGER, -- ID du groupe d’unités.
		Type CHAR(3), -- DEP = somme de dépôts, COM = commissions et EXT = exceptions
		dtDate DATETIME, -- Date du traitement pour type DEP et COM et date de l’exception pour EXT.
		Fee MONEY, -- Frais déposé.
		BenefInsur MONEY, -- Assurance bénéficiaire déposé.
		SubscInsur MONEY, -- Assurance souscripteur déposé.
		Advance MONEY, -- Avances sur commissions versées.
		CoveredAdvance MONEY, -- Avances sur commissions couvertes.
		Comm MONEY, -- Commissions de services versées.
		Bonus MONEY, -- Bonis d’affaires versées.
		RepLevelAndRole VARCHAR(150), -- Rôle et niveau du représentant.
		RepPct MONEY, -- Pourcentage de commissions versées à ce représentant.
		RepName VARCHAR(87) ) -- Nom, prénom du représentant.

	INSERT INTO #tUnitCommVsDep (
			UnitID, -- ID du groupe d’unités.
			Type, -- DEP = somme de dépôts, COM = commissions et EXT = exceptions
			dtDate, -- Date du traitement pour type DEP et COM et date de l’exception pour EXT.
			Fee, -- Frais déposé.
			BenefInsur, -- Assurance bénéficiaire déposé.
			SubscInsur, -- Assurance souscripteur déposé.
			Advance, -- Avances sur commissions versées.
			CoveredAdvance, -- Avances sur commissions couvertes.
			Comm, -- Commissions de services versées.
			Bonus, -- Bonis d’affaires versées.
			RepLevelAndRole, -- Rôle et niveau du représentant.
			RepPct, -- Pourcentage de commissions versées à ce représentant.
			RepName ) -- Nom, prénom du représentant.
		SELECT 
			C.UnitID,
			OperType = 'DEP',
			OperDate = MAX(T.RepTreatmentDate),
			Fee = SUM(C.Fee),
			BenefInsur = SUM(C.BenefInsur),
			SubscInsur = SUM(C.SubscInsur),
			Advance = 0,
			CoveredAdvance = 0,
			Comm = 0,
			Bonus = 0,
			RepRole = '',
			RepPct = 0,
			RepName = ''      
		FROM (
			SELECT
				T.RepTreatmentID,
				T.RepTreatmentDate,
				PreviousRepTreatmentDate = ISNULL(MAX(O.RepTreatmentDate), 0)
			FROM Un_RepTreatment T
			LEFT JOIN Un_RepTreatment O ON O.RepTreatmentID < T.RepTreatmentID
			GROUP BY
				T.RepTreatmentID,
				T.RepTreatmentDate
			) T  
		JOIN Un_Cotisation C ON C.UnitID = @UnitID
		JOIN Un_Oper O ON O.OperID = C.OperID
		WHERE O.OperDate BETWEEN DATEADD(DAY, 1, T.PreviousRepTreatmentDate) AND T.RepTreatmentDate
			AND( C.Fee <> 0 
				OR C.BenefInsur <> 0 OR C.SubscInsur <> 0
				)
		GROUP BY
			T.RepTreatmentID,
			C.UnitID
		-----
		UNION
		-----
		SELECT 
			VBC.UnitID,
			OperType = 'COM',
			OperDate = T.RepTreatmentDate,
			Fee = 0,
			BenefInsur = 0,
			SubscInsur = 0,
			VBC.Advance,
			VBC.CoveredAdvance,  
			VBC.Comm,
			VBC.Bonus,
			RepRole = ISNULL(RR.RepRoleDesc, '') + ' ' + ISNULL(RL.LevelDesc, ''),
			VBC.RepPct,
			RepName = ISNULL(H.LastName, '') + ', ' + ISNULL(H.FirstName, '')          
		FROM Un_RepTreatment T
		JOIN (
			SELECT 
				VC.RepTreatmentID,
				VC.UnitID,
				VC.RepID,
				VC.RepLevelID,        
				RepPct = SUM(VC.RepPct),
				Advance = SUM(VC.Advance),
				CoveredAdvance = SUM(VC.CoveredAdvance),
				Comm = SUM(VC.Comm),
				Bonus = SUM(VC.Bonus)
			FROM Un_RepTreatment T
			JOIN (
				SELECT 
					C.RepTreatmentID,
					C.UnitID,
					C.RepID,
					C.RepLevelID,        
					RepPct = MAX(C.RepPct),
					Advance = SUM(C.AdvanceAmount),
					CoveredAdvance = SUM(C.CoveredAdvanceAmount),
					Comm = SUM(C.CommissionAmount),
					Bonus = 0
				FROM Un_RepCommission C
				WHERE C.UnitID = @UnitID
				GROUP BY
					C.RepTreatmentID,
					C.UnitID,
					C.RepID,
					C.RepLevelID
				-----
				UNION
				-----
				SELECT 
					B.RepTreatmentID,
					B.UnitID,
					B.RepID,
					B.RepLevelID,
					RepPct = 0,
					Advance = 0,
					CoveredAdvance = 0,
					Comm = 0,
					Bonus = SUM(B.BusinessBonusAmount)
				FROM Un_RepBusinessBonus B
				WHERE B.UnitID = @UnitID
				GROUP BY
					B.RepTreatmentID,
					B.UnitID,
					B.RepID,
					B.RepLevelID
				) VC ON VC.RepTreatmentID = T.RepTreatmentID
			GROUP BY
				VC.RepTreatmentID,
				VC.UnitID,
				VC.RepID,
				VC.RepLevelID
			) VBC ON VBC.RepTreatmentID = T.RepTreatmentID
		JOIN dbo.Mo_Human H ON H.HumanID = VBC.RepID
		JOIN Un_RepLevel RL ON RL.RepLevelID = VBC.RepLevelID
		JOIN Un_RepRole RR ON RR.RepRoleID = RL.RepRoleID
		WHERE VBC.UnitID = @UnitID
		-----
		UNION
		----- 
		SELECT
			V.UnitID,
			OperType = 'EXT',
			OperDate = V.RepExceptionDate,
			Fee = 0,
			BenefInsur = 0,
			SubscInsur = 0,
			Advance = V.AvdException,  
			CoveredAdvance = V.CadException,
			Comm = V.ComException,
			Bonus = 0,
			RepRole = ISNULL(RR.RepRoleDesc, '') + ' ' + ISNULL(RL.LevelDesc, ''),
			RepPct = 0,
			RepName = ISNULL(H.LastName, '') + ', ' + ISNULL(H.FirstName, '')          
		FROM (
			SELECT 
				E.UnitID,
				E.RepID,
				E.RepLevelID, 
				E.RepExceptionDate,
				ComException = SUM(E.ComException),
				AvdException = SUM(E.AvdException),
				CadException = SUM(E.CadException)
			FROM (
				SELECT 
					E.UnitID,
					E.RepID,
					E.RepLevelID, 
					E.RepExceptionDate,
					ComException = E.RepExceptionAmount,
					AvdException = 0,
					CadException = 0
				FROM Un_RepException E
				JOIN Un_RepExceptionType T ON T.RepExceptionTypeID = E.RepExceptionTypeID
				WHERE E.UnitID = @UnitID
					AND T.RepExceptionTypeTypeID = 'COM'
				-----
				UNION
				----- 
				SELECT 
					E.UnitID,
					E.RepID,
					E.RepLevelID, 
					E.RepExceptionDate,
					ComException = 0,
					AvdException = E.RepExceptionAmount,
					CadException = 0
				FROM Un_RepException E
				JOIN Un_RepExceptionType T ON T.RepExceptionTypeID = E.RepExceptionTypeID
				WHERE E.UnitID = @UnitID
					AND T.RepExceptionTypeTypeID = 'ADV'
				-----
				UNION
				----- 
				SELECT
					E.UnitID,
					E.RepID,
					E.RepLevelID, 
					E.RepExceptionDate,
					ComException = 0,
					AvdException = 0,
					CadException = E.RepExceptionAmount
				FROM Un_RepException E
				JOIN Un_RepExceptionType T ON T.RepExceptionTypeID = E.RepExceptionTypeID
				WHERE E.UnitID = @UnitID
					AND T.RepExceptionTypeTypeID = 'CAD'
				) E
			GROUP BY
				E.UnitID,
				E.RepID,
				E.RepLevelID,
				E.RepExceptionDate
			) V
		JOIN dbo.Mo_Human H ON H.HumanID = V.RepID
		JOIN Un_RepLevel RL ON RL.RepLevelID = V.RepLevelID
		JOIN Un_RepRole RR ON RR.RepRoleID = RL.RepRoleID
		WHERE V.UnitID = @UnitID
		ORDER BY
			OperDate,
			OperType,
			RepRole,
			RepName

	SELECT *
	FROM #tUnitCommVsDep

	DROP TABLE #tUnitCommVsDep
END


