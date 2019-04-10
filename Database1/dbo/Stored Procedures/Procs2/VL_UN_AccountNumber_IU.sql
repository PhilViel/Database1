/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_AccountNumber_IU
Description         :	Validation de sauvegarde d’ajout ou modification de numéro de compte.
Valeurs de retours  :	Dataset :
									Code 		VARCHAR(5)		Code d’erreur : ANU01 = « La date d’entrée en vigueur doit être
																	supérieure à la date du jour. ».  ANU02 = « Il ne peut y avoir
																	plus d’un numéro d’actif à la fois. ».
									Info1 	VARCHAR(100)	Premier champ d’information
									Info2 	VARCHAR(100)	Deuxième champ d’information
									Info3 	VARCHAR(100)	Troisième champ d’information
								Erreurs possibles :
									Code		Info1				Info2				Info3
									ANU01		NULL				NULL				NULL
									ANU02		NULL				NULL				NULL
Note                :	ADX0000739	IA	2005-08-10	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_AccountNumber_IU] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@iAccountNumberID INTEGER, -- ID unique du numéro de compte. (0 = ajout)
	@iAccountID INTEGER, -- ID unique du compte. 
	@dtStart DATETIME, -- 	Date d’entrée en vigueur du numéro de compte.
	@dtEnd DATETIME ) -- Date de fin de vigueur du numéro de compte.
AS
BEGIN
	-- Table des erreurs
	CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- ANU01 = « La date d’entrée en vigueur doit être supérieure à la date du jour. ».
	IF EXISTS (
		SELECT iAccountNumberID
		FROM Un_AccountNumber
		WHERE iAccountNumberID = @iAccountNumberID
			AND dtStart <> @dtStart
			AND dtStart < dbo.FN_CRQ_DateNoTime(GETDATE())
		)
		INSERT INTO #WngAndErr
			SELECT 
				'ANU01',
				'',
				'',
				''

	--	ANU02 = « Il ne peut y avoir plus d’un numéro d’actif à la fois. ».
	IF EXISTS (
		SELECT iAccountNumberID
		FROM Un_AccountNumber
		WHERE iAccountNumberID <> @iAccountNumberID
			AND iAccountID = @iAccountID
			AND(	@dtStart = dtStart
				OR	( @dtStart < dtStart 
					AND( @dtEnd IS NULL 
						OR @dtEnd >= dtStart
						)
					)
				OR	( @dtStart > dtStart 
					AND( dtEnd IS NULL 
						OR dtEnd >= @dtStart
						)
					)
				)
		)
		INSERT INTO #WngAndErr
			SELECT 
				'ANU02',
				'',
				'',
				''

	SELECT *
	FROM #WngAndErr
END

