/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_BatchRESUnit
Description 		:	Recupere les objets d'unités de résiliations par lot
Valeurs de retour	:	Table contenant les objets
Note					:	ADX0000693	IA	2005-05-17	Bruno Lapointe		Création
							ADX0002494	BR	2007-06-19	Bruno Lapointe		Int. Client gérer la virgule comme un point et faire un 
																						négatif.
************************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_BatchRESUnit (
	@iBlobID INTEGER ) -- Identifiant unique du blob
RETURNS @tBatchRESUnit
	TABLE (
		UnitID INTEGER, -- ID unique du groupe d'unités
		RESType CHAR(3), -- EPG = Épg. (Seulement les épargnes seront remboursées au souscripteur.  Les frais seront transférés (TFR) dans les frais disponibles de la convention pour les conventions collectives et dans les frais éliminés pour les conventions individuelles.) FEE = Épg., frais et ass. (Les épargnes, les frais, les primes d’assurance souscripteur et d’assurance bénéficiaire ainsi que les taxes seront remboursés au souscripteur.)
		UnitReductionReasonID INTEGER, -- Raison de la résiliation, par défaut vide. 
		IntINC MONEY -- Intérêt client
		)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@UnitID INTEGER,
		@RESType CHAR(3),
		@UnitReductionReasonID INTEGER,
		@IntINC MONEY,
		----------------
		@iObjectID INTEGER,
		@iCurrentObjectID INTEGER,
		@vcFieldName VARCHAR(100),
		@vcValue VARCHAR(100)

	SET @iCurrentObjectID = 0

	DECLARE crBatchRESUnitObj CURSOR FOR
		SELECT 
			iObjectID,
			vcFieldName,
			SUBSTRING(txValue, 1, 100)
		FROM dbo.FN_CRQ_DecodeBlob(@iBlobID)
		WHERE vcClassName = 'UN_BatchRESUnit'
		ORDER BY iObjectID 

	OPEN crBatchRESUnitObj

	FETCH NEXT FROM crBatchRESUnitObj
	INTO
		@iObjectID,
		@vcFieldName,
		@vcValue

	SET @iCurrentObjectID = @iObjectID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @vcFieldName = 'UnitID' 
			SET @UnitID = CAST(@vcValue AS INTEGER)
		ELSE IF @vcFieldName = 'RESType' 
			SET @RESType = SUBSTRING(@vcValue, 1, 3)
		ELSE IF @vcFieldName = 'UnitReductionReasonID' 
			SET @UnitReductionReasonID = CAST(@vcValue AS INTEGER)
		ELSE IF @vcFieldName = 'IntINC'
			SET @IntINC = -CAST(REPLACE(@vcValue, ',', '.') AS MONEY)

		FETCH NEXT FROM crBatchRESUnitObj
		INTO
			@iObjectID,
			@vcFieldName,
			@vcValue

		-- Vérifie si on vient de changer d'objet ou encore si on a tout lu (dernier objet lu).
		IF @iCurrentObjectID <> @iObjectID
		OR @@FETCH_STATUS <> 0
		BEGIN
			-- Insère l'objet qu'on vient de finir de lire.
			INSERT INTO @tBatchRESUnit (
				UnitID, -- ID unique du groupe d'unités
				RESType, -- EPG = Épg. (Seulement les épargnes seront remboursées au souscripteur.  Les frais seront transférés (TFR) dans les frais disponibles de la convention pour les conventions collectives et dans les frais éliminés pour les conventions individuelles.) FEE = Épg., frais et ass. (Les épargnes, les frais, les primes d’assurance souscripteur et d’assurance bénéficiaire ainsi que les taxes seront remboursés au souscripteur.)
				UnitReductionReasonID, -- Raison de la résiliation, par défaut vide. 
				IntINC ) -- Intérêt client
			VALUES (
				@UnitID,
				@RESType,
				@UnitReductionReasonID,
				@IntINC )

			-- Remet les variables de champs vides pour le prochain objet.
			SET @UnitID = NULL
			SET @RESType = NULL
			SET @UnitReductionReasonID = NULL
			SET @IntINC = NULL

			-- Met à jour la variable donnant l'objet présentement traité.
			IF @@FETCH_STATUS = 0
				SET @iCurrentObjectID = @iObjectID
		END
	END

	CLOSE crBatchRESUnitObj
	DEALLOCATE crBatchRESUnitObj

	-- Fin des traitements
	RETURN
END
