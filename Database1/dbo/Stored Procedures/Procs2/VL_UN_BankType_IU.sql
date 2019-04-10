/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_BankType_IU
Description         :	Procédure de validation d’ajout/modification d’institutions financières.
Valeurs de retours  :	Dataset :
									Code 		VARCHAR(5)		Code d’erreur : INF01 = « Le code est déjà utilisé! ».  INF02 =
																	« La modification du code de cette institution affectera
																	[Nb. Compte] compte bancaire et [Nb. CPA] CPA! ».
									Info1 	VARCHAR(100)	Premier champ d’information
									Info2 	VARCHAR(100)	Deuxième champ d’information
									Info3 	VARCHAR(100)	Troisième champ d’information
								Erreurs possibles :
									Code		Info1				Info2				Info3
									INF01		NULL				NULL				NULL
									INF02		Nb. compte		Nb. CPA			NULL
Note                :	ADX0000721	IA	2005-07-08	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_BankType_IU] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@BankTypeID INTEGER, -- ID unique de l'institution financière à sauvegarder, 0 pour ajouter.
	@BankTypeCode VARCHAR(75), -- Code de l'institution financière.
	@BankTypeName VARCHAR(75) ) -- Nom de l'institution financière.
AS
BEGIN
	-- Table des erreurs
	CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- INF01 = « Le code est déjà utilisé! ».
	IF EXISTS 
		(
		SELECT *
		FROM Mo_BankType
		WHERE BankTypeCode = @BankTypeCode
			AND BankTypeID <> @BankTypeID
		)
		INSERT INTO #WngAndErr
			SELECT 
				'INF01',
				'',
				'',
				''

	-- INF02 = « La modification du code de cette institution affectera [Nb. Compte] compte bancaire et [Nb. CPA] CPA! ».
	IF @BankTypeID > 0
		INSERT INTO #WngAndErr
			SELECT 
				'INF02',
				CAST(COUNT(DISTINCT CA.ConventionID) AS VARCHAR(30)),
				CAST(COUNT(DISTINCT OAI.OperID) AS VARCHAR(30)),
				''
			FROM Mo_BankType T
			JOIN Mo_Bank B ON B.BankTypeID = T.BankTypeID
			LEFT JOIN Un_ConventionAccount CA ON CA.BankID = B.BankID
			LEFT JOIN Un_OperAccountInfo OAI ON OAI.BankID = B.BankID
			WHERE @BankTypeID = T.BankTypeID
				AND T.BankTypeCode <> @BankTypeCode
			GROUP BY B.BankTypeID
			HAVING COUNT(DISTINCT CA.ConventionID) > 0
				OR COUNT(DISTINCT OAI.OperID) > 0

	SELECT *
	FROM #WngAndErr
END

