/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_Bank_IU
Description         :	Procédure de validation d’ajout/modification d’institutions financières.
Valeurs de retours  :	Dataset :
									Code 		VARCHAR(5)		Code d’erreur : SUC01 = « Le transit est déjà utilisé pour cette
																	institution! ».  SUC02 = « La modification du transit de cette
																	succursale affectera [Nb. Compte] compte bancaire et [Nb. CPA]
																	CPA! ».
									Info1 	VARCHAR(100)	Premier champ d’information
									Info2 	VARCHAR(100)	Deuxième champ d’information
									Info3 	VARCHAR(100)	Troisième champ d’information
								Erreurs possibles :
									Code		Info1				Info2				Info3
									SUC01		NULL				NULL				NULL
									SUC02		Nb. compte		Nb. CPA			NULL
Note                :	ADX0000721	IA	2005-07-08	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Bank_IU] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@BankID INTEGER, -- ID unique de la succursale à sauvegarder, 0 pour ajouter.
	@BankTypeID INTEGER, -- ID unique de l'institution financière.
	@BankTransit VARCHAR(75) ) -- Transit de la succursale.
AS
BEGIN
	-- Table des erreurs
	CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- SUC01 = « Le transit est déjà utilisé pour cette institution! ».
	IF EXISTS 
		(
		SELECT *
		FROM Mo_Bank
		WHERE BankTransit = @BankTransit
			AND BankTypeID = @BankTypeID
			AND BankID <> @BankID
		)
		INSERT INTO #WngAndErr
			SELECT 
				'SUC01',
				'',
				'',
				''

	-- SUC02 = « La modification du transit de cette succursale affectera [Nb. Compte] compte bancaire et [Nb. CPA] CPA! ».
	IF @BankID > 0
		INSERT INTO #WngAndErr
			SELECT 
				'SUC02',
				CAST(COUNT(DISTINCT CA.ConventionID) AS VARCHAR(30)),
				CAST(COUNT(DISTINCT OAI.OperID) AS VARCHAR(30)),
				''
			FROM Mo_Bank B
			LEFT JOIN Un_ConventionAccount CA ON CA.BankID = B.BankID
			LEFT JOIN Un_OperAccountInfo OAI ON OAI.BankID = B.BankID
			WHERE @BankID = B.BankID
				AND B.BankTransit <> @BankTransit
			GROUP BY B.BankID
			HAVING COUNT(DISTINCT CA.ConventionID) > 0
				OR COUNT(DISTINCT OAI.OperID) > 0

	SELECT *
	FROM #WngAndErr
END

