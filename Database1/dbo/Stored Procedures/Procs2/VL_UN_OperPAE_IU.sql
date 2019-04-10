/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/***********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_OperPAE_IU
Description         :	Procédure de validation avant la sauvegarde d’ajout/modification d'un PAE.
Exemple d'appel		:   EXEC dbo.VL_UN_OperPAE_IU 2
Valeurs de retours  :	Dataset : (Vide = pas d’erreur dans les validations)
				vcCode	VARCHAR(5)	Code de d’erreur
				vcInfo1	VARCHAR(100)	Première information supplémentaire, permet de faire des messages détaillés.
				vcInfo2	VARCHAR(100)	Deuxième information supplémentaire.
				vcInfo3	VARCHAR(100)	Troisième information supplémentaire.
					
			ReturnValue :
				> 0 : Réussite
				<= 0 : Erreurs.

Note                :	ADX0001007	IA	2006-05-29	Alain Quirion		Création								
						ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
										2010-01-19	Jean-F. Gauthier	Ajout du champ EligibilityConditionID
										2010-04-08	Jean-François Gauthier	Ajout de la validation du statut de la convention
																			afin de bloquer le traitement si l'état = "Proposition"
										2012-04-05	Donald Huppé		Enlever message GEN12 afin de faire des PAE postdaté (voir ME Nicolas)
                                        2015-12-01  Steeve Picard       Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_OperPAE_IU] (
	@iBlobID INT)	--ID du blob
AS
BEGIN

    SELECT 1/0
    /*	
    --Code	GEN01
	--Message	Pas de détail d'opération.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN02
	--Message	Pas d'opération.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN03
	--Message	Plus d'une opération avec le même OperID.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN04
	--Message	Le blob n'existe pas.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN05
	--Message	Update du blob par le service pas encore fait.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide

	--Code	GEN06
	--Message	Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot.
	--Info1 : Vide					Info2 : Vide						Info3 : Vide
	
	--GEN12 -> Transaction refusée, car la convention est à l'état "Proposition"
	--			Info1 : Vide					Info2 : Vide						Info3 : Vide
	
	--Code	PAE01
	--Message	Le montant de l’opération PAE doit être plus petit que 0.00$.
	--Info1	OperID

	--Code	PAE02
	--Message	La somme des retenues des deux opérations devra donner 0.00$.

	--Code	PAE03
	--Message	Le montant remboursé ne peut pas être plus élevé que le solde d'intérêts, d'int. (TIN), d'int SCEE, d'int. PCEE (TIN), d’int. SCEE+, d’int. BEC, de SCEE, SCEE+ et BEC de la convention.
	--Info1	LigneTrans
	--Info2	Type d'argent (Intérêts, Int. TIN, Int. SCEE, Int. PCEE TIN, Int. SCEE+, Int. BEC, SCEE, SCEE+ et BEC)
	--Info3	ConventionNo et InForceDate

	--Code	PAE04
	--Message	La date d’opération doit être plus grande que la date de barrure du système.

	-- Result = -1 -> Le blob n'existe pas
	-- Result = -2 -> Update du blob par le service par encore fait
	-- Result = -3 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
	-- Result = -10 -> Erreur à la suppression du blob

	DECLARE 
		@Result INT

	CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- Validation du blob
	EXEC @Result = VL_UN_BlobFormatOfOper @iBlobID

	IF @Result < 0
	BEGIN
		-- GEN04 -> Le blob n'existe pas
		-- GEN05 -> Update du blob par le service pas encore fait
		-- GEN06 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
		INSERT INTO #WngAndErr
			SELECT 
				CASE @Result
					WHEN -1 THEN 'GEN04'
					WHEN -2 THEN 'GEN05'
					WHEN -3 THEN 'GEN06'
				END,
				'',
				'',
				''
	END
	ELSE
	BEGIN
		-- Tables temporaires créé à partir du blob contenant l'opération
		DECLARE @OperTable TABLE (
							LigneTrans	INT,
							OperID		INT,
							ConnectID	INT,
							OperTypeID	CHAR(3),
							OperDate	DATETIME)
	
		-- Tables temporaires créé à partir du blob contenant les opérations sur conventions et les subventions
		DECLARE @ConventionOperTable TABLE (
							LigneTrans			INT,
							ConventionOperID	INT,
							OperID				INT,
							ConventionID		INT,
							ConventionOperTypeID VARCHAR(3),
							ConventionOperAmount MONEY,
							vcEtatConv			VARCHAR(3)) -- 2010-04-08 : JFG : Ajout du champ
	
		-- Table temporaire de paiement de bourses
		DECLARE @ScholarshipPmtTable TABLE (
			ScholarshipPmtID INT,
			OperID INT,
			ScholarshipID INT,
			CollegeID INT,
			ProgramID INT,
			StudyStart DATETIME,
			ProgramLength INT,
			ProgramYear INT,
			RegistrationProof BIT,
			SchoolReport BIT,
			EligibilityQty INT,
			CaseOfJanuary BIT,
			EligibilityConditionID CHAR(3))

		-- Rempli la table temporaire de l'opération
		INSERT INTO @OperTable
		(
			LigneTrans,
			OperID,
			ConnectID,
			OperTypeID,
			OperDate
		)
		SELECT 
			LigneTrans,
			OperID,
			ConnectID,
			OperTypeID,
			OperDate
		FROM 
			dbo.FN_UN_OperOfBlob(@iBlobID)
	
		-- Rempli la table temporaire des opérations sur conventions et des subventions
		INSERT INTO @ConventionOperTable
		(
			LigneTrans,
			ConventionOperID,
			OperID,
			ConventionID,
			ConventionOperTypeID,
			ConventionOperAmount
		)
		SELECT 
			LigneTrans,
			ConventionOperID,
			OperID,
			ConventionID,
			ConventionOperTypeID,
			ConventionOperAmount 
		FROM 
			dbo.FN_UN_ConventionOperOfBlob(@iBlobID)	

		-- Rempli la table temporaire de paiements de bourse
		INSERT INTO @ScholarshipPmtTable
			SELECT *
			FROM dbo.FN_UN_ScholarshipPmtOfBlob(@iBlobID)	

		-- GEN01 : Pas de détail d'opération
		IF NOT EXISTS (SELECT ConventionOperID FROM @ConventionOperTable)
			INSERT INTO #WngAndErr
				SELECT 
					'GEN01',
					'',
					'',
					''
	
		-- GEN02 : Pas d'opération
		IF NOT EXISTS (SELECT OperID FROM @OperTable) 
			INSERT INTO #WngAndErr
				SELECT 
					'GEN02',
					'',
					'',
					''
	
		-- GEN03 : Plus d'une opération avec le même OperID
		IF EXISTS (SELECT OperID, COUNT(OperID) FROM @OperTable GROUP BY OperID HAVING COUNT(OperID) > 1) 
			INSERT INTO #WngAndErr
				SELECT 
					'GEN03',
					'',
					'',
					''
		
		-- *************** 2010-04-08 : Ajout : JFG  *************************
		-- GEN12 : Validation de l'état des conventions
		UPDATE	co
		SET		co.vcEtatConv = s.ConventionStateID
		FROM		@ConventionOperTable co
                    INNER JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GETDATE(), NULL) s on s.ConventionID = co.ConventionID

		/*	
		IF EXISTS(SELECT 1 FROM @ConventionOperTable WHERE vcEtatConv = 'PRP')
			BEGIN
				INSERT INTO #WngAndErr
				(
					Code,
					Info1,
					Info2,
					Info3
				)
				SELECT 
					'GEN12',
					'',
					'',
					''
			END
			*/
		-- ************ FIN MODIFICICATION DU 2010-04-08 *********************
	
		-- Variable qu'on a besoin dans plus d'une validation
		DECLARE
			@LastVerifDate DATETIME,
			@SumConventionOper MONEY

		SET @SumConventionOper = 0
	
		SELECT 
			@LastVerifDate = LastVerifDate
		FROM Un_Def

		SELECT 
			@SumConventionOper = ISNULL(SUM(ConventionOperAmount),0)
		FROM @ConventionOperTable	
	
		-- Validation sur PAE
		IF EXISTS (
				SELECT OperID
				FROM @OperTable
				WHERE OperTypeID = 'PAE')
		BEGIN
			-- PAE01 -> Le montant de l’opération PAE doit être plus petit que 0.00$.
			INSERT INTO #WngAndErr
				SELECT 
					'PAE01',
					CAST(O.OperID AS VARCHAR(100)),
					'',
					''
				FROM @OperTable O					
				LEFT JOIN (
					SELECT 
						OperID,
						SumConventionOper = SUM(ConventionOperAmount)
					FROM @ConventionOperTable
					GROUP BY OperID
					) CO ON CO.OperID = O.OperID
				WHERE O.OperTypeID IN ('PAE','RGC')
				  AND ISNULL(CO.SumConventionOper,0) >= 0
			
			-- PAE02 -> La somme des retenues des deux opérations devra donner 0.00$.
			IF EXISTS (
					SELECT
						SUM(ConventionOperAmount)
					FROM @ConventionOperTable
					WHERE ConventionOperTypeID = 'RTN'					
					GROUP BY ConventionID		
					HAVING SUM(ConventionOperAmount) <> 0			
					)
				INSERT INTO #WngAndErr
					SELECT 
						'PAE02',
						'',
						'',
						''

			-- PAE03 -> Le montant remboursé ne peut pas être plus élevé que le solde d'intérêts, d'int. (TIN), d'int SCEE, d'int. PCEE (TIN), d'int SCEE+, d’int. BEC, de SCEE, SCEE+ et BEC de la convention
			INSERT INTO #WngAndErr
				SELECT
					'PAE03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'Intérêts',
					C.ConventionNo
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'INM'
					GROUP BY CO.ConventionID
					) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID = 'IND' -- Validation sur individuel seulement
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1
					FROM Un_ConventionOper CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'INM'
					GROUP BY CO.ConventionID
					) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount)
					FROM Un_ConventionOper CO
					JOIN (
						SELECT DISTINCT CO.ConventionID
						FROM @ConventionOperTable CO
						JOIN @OperTable OT ON OT.OperID = CO.OperID
						WHERE OT.OperTypeID = 'PAE'
							AND CO.ConventionOperTypeID = 'INM'
						) T ON CO.ConventionID = T.ConventionID
					WHERE CO.ConventionOperTypeID = 'INM'
					GROUP BY CO.ConventionID
					) CO ON CO.ConventionID = N.ConventionID
				WHERE ((N.ConventionOperAmount > 0) -- Vérifie si on retire des intérêts
					AND (N.ConventionOperAmount > ISNULL(O.ConventionOperAmount,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.ConventionOperAmount - ISNULL(O.ConventionOperAmount,0) > ISNULL(CO.ConventionOperAmount,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'PAE03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'Int. TIN',
					C.ConventionNo
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'ITR'
					GROUP BY CO.ConventionID
					) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID = 'IND' -- Validation sur individuel seulement
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1
					FROM Un_ConventionOper CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'ITR'
					GROUP BY CO.ConventionID
					) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount)
					FROM Un_ConventionOper CO
					JOIN (
						SELECT DISTINCT CO.ConventionID
						FROM @ConventionOperTable CO
						JOIN @OperTable OT ON OT.OperID = CO.OperID
						WHERE OT.OperTypeID = 'PAE'
							AND CO.ConventionOperTypeID = 'ITR'
						) T ON CO.ConventionID = T.ConventionID
					WHERE CO.ConventionOperTypeID = 'ITR'
					GROUP BY CO.ConventionID
					) CO ON CO.ConventionID = N.ConventionID
				WHERE ((N.ConventionOperAmount > 0) -- Vérifie si on retire des intérêts TIN
					AND (N.ConventionOperAmount > ISNULL(O.ConventionOperAmount,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.ConventionOperAmount - ISNULL(O.ConventionOperAmount,0) > ISNULL(CO.ConventionOperAmount,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'PAE03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'Int. SCEE',
					C.ConventionNo
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'INS'
					GROUP BY CO.ConventionID
					) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID = 'IND' -- Validation sur individuel seulement
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1
					FROM Un_ConventionOper CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'INS'
					GROUP BY CO.ConventionID
					) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount)
					FROM Un_ConventionOper CO
					JOIN (
						SELECT DISTINCT CO.ConventionID
						FROM @ConventionOperTable CO
						JOIN @OperTable OT ON OT.OperID = CO.OperID
						WHERE OT.OperTypeID = 'PAE'
							AND CO.ConventionOperTypeID = 'INS'
						) T ON CO.ConventionID = T.ConventionID
					WHERE CO.ConventionOperTypeID = 'INS'
					GROUP BY CO.ConventionID
					) CO ON CO.ConventionID = N.ConventionID
				WHERE ((N.ConventionOperAmount > 0) -- Vérifie si on retire des intérêts SCEE
					AND (N.ConventionOperAmount > ISNULL(O.ConventionOperAmount,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.ConventionOperAmount - ISNULL(O.ConventionOperAmount,0) > ISNULL(CO.ConventionOperAmount,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'PAE03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'Int. PCEE TIN',
					C.ConventionNo
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'IST'
					GROUP BY CO.ConventionID
					) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID = 'IND' -- Validation sur individuel seulement
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1
					FROM Un_ConventionOper CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'IST'
					GROUP BY CO.ConventionID
					) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount)
					FROM Un_ConventionOper CO
					JOIN (
						SELECT DISTINCT CO.ConventionID
						FROM @ConventionOperTable CO
						JOIN @OperTable OT ON OT.OperID = CO.OperID
						WHERE OT.OperTypeID = 'PAE'
							AND CO.ConventionOperTypeID = 'IST'
						) T ON CO.ConventionID = T.ConventionID
					WHERE CO.ConventionOperTypeID = 'IST'
					GROUP BY CO.ConventionID
					) CO ON CO.ConventionID = N.ConventionID
				WHERE ((N.ConventionOperAmount > 0) -- Vérifie si on retire des intérêts PCEE TIN
					AND (N.ConventionOperAmount > ISNULL(O.ConventionOperAmount,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.ConventionOperAmount - ISNULL(O.ConventionOperAmount,0) > ISNULL(CO.ConventionOperAmount,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'PAE03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'Int. SCEE+',
					C.ConventionNo
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'IS+'
					GROUP BY CO.ConventionID
					) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID = 'IND' -- Validation sur individuel seulement
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1
					FROM Un_ConventionOper CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'IS+'
					GROUP BY CO.ConventionID
					) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount)
					FROM Un_ConventionOper CO
					JOIN (
						SELECT DISTINCT CO.ConventionID
						FROM @ConventionOperTable CO
						JOIN @OperTable OT ON OT.OperID = CO.OperID
						WHERE OT.OperTypeID = 'PAE'
							AND CO.ConventionOperTypeID = 'IS+'
						) T ON CO.ConventionID = T.ConventionID
					WHERE CO.ConventionOperTypeID = 'IS+'
					GROUP BY CO.ConventionID
					) CO ON CO.ConventionID = N.ConventionID
				WHERE ((N.ConventionOperAmount > 0) -- Vérifie si on retire des intérêts SCEE+
					AND (N.ConventionOperAmount > ISNULL(O.ConventionOperAmount,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.ConventionOperAmount - ISNULL(O.ConventionOperAmount,0) > ISNULL(CO.ConventionOperAmount,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'PAE03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'Int. BEC',
					C.ConventionNo
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'IBC'
					GROUP BY CO.ConventionID
					) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID = 'IND' -- Validation sur individuel seulement
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount) * -1
					FROM Un_ConventionOper CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'IBC'
					GROUP BY CO.ConventionID
					) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						CO.ConventionID,
						ConventionOperAmount = SUM(CO.ConventionOperAmount)
					FROM Un_ConventionOper CO
					JOIN (
						SELECT DISTINCT CO.ConventionID
						FROM @ConventionOperTable CO
						JOIN @OperTable OT ON OT.OperID = CO.OperID
						WHERE OT.OperTypeID = 'PAE'
							AND CO.ConventionOperTypeID = 'IBC'
						) T ON CO.ConventionID = T.ConventionID
					WHERE CO.ConventionOperTypeID = 'IBC'
					GROUP BY CO.ConventionID
					) CO ON CO.ConventionID = N.ConventionID
				WHERE ((N.ConventionOperAmount > 0) -- Vérifie si on retire des intérêts du BEC
					AND (N.ConventionOperAmount > ISNULL(O.ConventionOperAmount,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.ConventionOperAmount - ISNULL(O.ConventionOperAmount,0) > ISNULL(CO.ConventionOperAmount,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'PAE03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'SCEE',
					C.ConventionNo
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						CO.ConventionID,
						fCESG = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'SUB'
					GROUP BY CO.ConventionID
					) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID = 'IND' -- Validation sur individuel seulement
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						CE.ConventionID,
						fCESG = SUM(CE.fCESG) * -1
					FROM Un_CESP CE
					JOIN @OperTable OT ON OT.OperID = CE.OperID
					WHERE OT.OperTypeID = 'PAE'
					GROUP BY CE.ConventionID
					) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						CE.ConventionID,
						fCESG = SUM(CE.fCESG)
					FROM Un_CESP CE
					JOIN (
						SELECT DISTINCT CO.ConventionID
						FROM @ConventionOperTable CO
						JOIN @OperTable OT ON OT.OperID = CO.OperID
						WHERE OT.OperTypeID = 'PAE'
							AND CO.ConventionOperTypeID = 'SUB'
						) T ON CE.ConventionID = T.ConventionID
					GROUP BY CE.ConventionID
					) CE ON CE.ConventionID = N.ConventionID
				WHERE ((N.fCESG > 0) 
					AND (N.fCESG > ISNULL(O.fCESG,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.fCESG - ISNULL(O.fCESG,0) > ISNULL(CE.fCESG,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'PAE03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'SCEE+',
					C.ConventionNo
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						CO.ConventionID,
						fACESG = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'SU+'
					GROUP BY CO.ConventionID
					) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID = 'IND' -- Validation sur individuel seulement
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						CE.ConventionID,
						fACESG = SUM(CE.fACESG) * -1
					FROM Un_CESP CE
					JOIN @OperTable OT ON OT.OperID = CE.OperID
					WHERE OT.OperTypeID = 'PAE'
					GROUP BY CE.ConventionID
					) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						CE.ConventionID,
						fACESG = SUM(CE.fACESG)
					FROM Un_CESP CE
					JOIN (
						SELECT DISTINCT CO.ConventionID
						FROM @ConventionOperTable CO
						JOIN @OperTable OT ON OT.OperID = CO.OperID
						WHERE OT.OperTypeID = 'PAE'
							AND CO.ConventionOperTypeID = 'SU+'
						) T ON CE.ConventionID = T.ConventionID
					GROUP BY CE.ConventionID
					) CE ON CE.ConventionID = N.ConventionID
				WHERE ((N.fACESG > 0) 
					AND (N.fACESG > ISNULL(O.fACESG,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.fACESG - ISNULL(O.fACESG,0) > ISNULL(CE.fACESG,0))) -- Vérifie que le montant soit disponible
				-----
				UNION
				-----
				SELECT
					'PAE03',
					CAST(N.LigneTrans AS VARCHAR(100)),
					'BEC',
					C.ConventionNo
				FROM ( -- Montant qu'on veut sauvegarder
					SELECT 
						CO.ConventionID,
						fCLB = SUM(CO.ConventionOperAmount) * -1,
						LigneTrans = MAX(CO.LigneTrans)
					FROM @ConventionOperTable CO
					JOIN @OperTable OT ON OT.OperID = CO.OperID
					WHERE OT.OperTypeID = 'PAE'
						AND CO.ConventionOperTypeID = 'BEC'
					GROUP BY CO.ConventionID
					) N
				JOIN dbo.Un_Convention C ON C.ConventionID = N.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID AND P.PlanTypeID = 'IND' -- Validation sur individuel seulement
				-- Montant retiré avant la modification (si pas ajout)
				LEFT JOIN (
					SELECT 
						CE.ConventionID,
						fCLB = SUM(CE.fCLB) * -1
					FROM Un_CESP CE
					JOIN @OperTable OT ON OT.OperID = CE.OperID
					WHERE OT.OperTypeID = 'PAE'
					GROUP BY CE.ConventionID
					) O ON O.ConventionID = N.ConventionID
				LEFT JOIN ( -- Montant de cotisation disponible avant modification ou ajout
					SELECT 
						CE.ConventionID,
						fCLB = SUM(CE.fCLB)
					FROM Un_CESP CE
					JOIN (
						SELECT DISTINCT CO.ConventionID
						FROM @ConventionOperTable CO
						JOIN @OperTable OT ON OT.OperID = CO.OperID
						WHERE OT.OperTypeID = 'PAE'
							AND CO.ConventionOperTypeID = 'BEC'
						) T ON CE.ConventionID = T.ConventionID
					GROUP BY CE.ConventionID
					) CE ON CE.ConventionID = N.ConventionID
				WHERE ((N.fCLB > 0) 
					AND (N.fCLB > ISNULL(O.fCLB,0)) -- Vérifie si le nouveau montant retiré est plus grand que l'ancien
					AND (N.fCLB - ISNULL(O.fCLB,0) > ISNULL(CE.fCLB,0))) -- Vérifie que le montant soit disponible

			-- PAE04 -> La date d’opération doit être plus grande que la date de barrure du système
			INSERT INTO #WngAndErr
				SELECT 
					'PAE04',
					'',
					'',
					''
				FROM @OperTable OT
				LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
				WHERE ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@LastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
					OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@LastVerifDate)
		END
	END

	-- Fait le ménage dans les blob vieux de 2 jours ou plus
	IF @Result <= 0
	BEGIN
		DELETE 
		FROM CRI_Blob
		WHERE dtBlob <= DATEADD(DAY,-2,GETDATE())
	
		IF @@ERROR <> 0
		AND @Result > 0
			SET @Result = -10 -- Erreur à la suppression du blob
	END

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr;

	RETURN @Result
    */
END