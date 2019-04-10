/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	TT_UN_HoldPayementOnNoSINConvention
Description         :	Procédure qui crée des arrêts de paiement de type « Résiliation sans NAS » 
						sur les conventions du blob.
Valeurs de retours  :	@ReturnValue :
							> 0 : Réussite
							<= 0 : Échec.

Note                :	ADX0001344	IA	2007-04-17	Alain Quirion		Création
						GLPI6983		2012-02-10  Eric Michaud		Modification pour suivie des modifications
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_HoldPayementOnNoSINConvention] (
	@iBlobID	INTEGER,
	@ConnectID	INTEGER)	--	ID du blob de la table CRI_Blob qui contient 
AS							--  les « ConventionID » des conventions sur lesquelles on doit inscrire les arrêts de paiements.
BEGIN
	DECLARE @iResult INT,
			@iID_Utilisateur INT,
			@Today DATETIME

	SET @iResult = 1

	SET @Today = dbo.FN_CRQ_DateNoTime(GETDATE())

    SELECT TOP 1 @iID_Utilisateur = USR.UserID
    FROM Mo_Connect CON 
		INNER JOIN Mo_User USR ON USR.UserID = CON.UserID
    WHERE CON.ConnectID = @ConnectID;

	CREATE TABLE #tConventionNoSIN(
		ConventionID INTEGER PRIMARY KEY)

	INSERT INTO #tConventionNoSIN
		SELECT 
				C.ConventionID				
		FROM dbo.Un_Convention C
		JOIN dbo.FN_CRI_BlobToIntegerTable(@iBlobID) V ON V.iVal = C.ConventionID
	
	BEGIN TRANSACTION

	--Suppression des arrêts de paiement ultérieurs à la date du jour
	DELETE Un_Breaking
	FROM Un_Breaking
	JOIN #tConventionNoSIN C ON C.ConventionID = Un_Breaking.ConventionID
	WHERE Un_Breaking.BreakingStartDate >= @Today

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		--Insertion des arrêts de paiements de type RNA en lot
		INSERT INTO Un_Breaking(ConventionID, BreakingTypeID, BreakingStartDate, BreakingEndDate, BreakingReason)
			SELECT 
					ConventionID,
					'RNA',
					@Today,
					NULL,
					'Arrêt de paiement en lot'
			FROM #tConventionNoSIN

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	--Modification des arrêts de paiement en vigueur différent de RNA
	IF @iResult > 0
	BEGIN
		UPDATE Un_Breaking
		SET Un_Breaking.BreakingEndDate = @Today-1
		FROM Un_Breaking
		JOIN #tConventionNoSIN C ON C.ConventionID = Un_Breaking.ConventionID
		WHERE Un_Breaking.BreakingStartDate < @Today --On ne tient pas compte d'aujourhdui car ils vont avoir été supprimé d'abord
				AND ISNULL(Un_Breaking.BreakingEndDate,'9999-12-31') >= @Today
				AND Un_Breaking.BreakingTypeID <> 'RNA'

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION
END


