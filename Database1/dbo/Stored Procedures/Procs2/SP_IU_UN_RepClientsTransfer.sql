/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_IU_UN_RepClientsTransfer
Description         :	Procédure de transfert de client de représentant
Valeurs de retours  :	1 : Transfert réussi
								-1 : Erreur SQL
Note                :	ADX0000330	IA	2004-06-14	Bruno Lapointe			Création
								ADX0001378	BR	2005-04-05	Bruno Lapointe			Ajout du log
								ADX0001380	BR	2005-04-06	Bruno Lapointe			Blob au lieu de varchar pour ID de souscripteurs
								ADX0001378	BR	2005-05-05	Bruno Lapointe			Correction de l'inversion du log.
*************************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_UN_RepClientsTransfer] (
	@ConnectID INTEGER, -- Identifiant unique de la connection
	@BlobOfSubscriberIDs INTEGER, -- ID unique du blob qui contient la liste des souscripteurs que l'on transfert au représentant
	@RepID INTEGER) -- ID Unique du représentant à qui l'on transfert les souscripteurs

AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@cSep CHAR(1)

	SET @cSep = CHAR(30)

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Insère un log de l'objet modifié.
	INSERT INTO CRQ_Log (
			ConnectID,
			LogTableName,
			LogCodeID,
			LogTime,
			LogActionID,
			LogDesc,
			LogText )
		SELECT
			@ConnectID,
			'Un_Subscriber',
			S.SubscriberID,
			GETDATE(),
			LA.LogActionID,
			LogDesc = 'Souscripteur : '+H.LastName+', '+H.FirstName,
			LogText =
				CASE 
					WHEN ISNULL(@RepID,0) <> ISNULL(S.RepID,0) THEN
						'RepID'+@cSep+
						CASE 
							WHEN ISNULL(S.RepID,0) <= 0 THEN ''
						ELSE CAST(S.RepID AS VARCHAR)
						END+@cSep+
						CASE 
							WHEN ISNULL(@RepID,0) <= 0 THEN ''
						ELSE CAST(@RepID AS VARCHAR)
						END+@cSep+
						ISNULL(OHR.LastName+', '+OHR.FirstName,'')+@cSep+
						ISNULL(HR.LastName+', '+HR.FirstName,'')+@cSep+
						CHAR(13)+CHAR(10)
				ELSE ''
				END
			FROM dbo.Un_Subscriber S
			JOIN dbo.FN_CRQ_BlobToIntegerTable(@BlobOfSubscriberIDs) V ON V.Val = S.SubscriberID
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = @RepID
			LEFT JOIN dbo.Mo_Human OHR ON OHR.HumanID = S.RepID
			JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
		
	IF @@ERROR = 0
		-- Change le représentant
		UPDATE dbo.Un_Subscriber 
		SET 
			RepID = @RepID
		FROM dbo.Un_Subscriber 
		JOIN dbo.FN_CRQ_BlobToIntegerTable(@BlobOfSubscriberIDs) S ON S.Val = Un_Subscriber.SubscriberID

	IF @@ERROR = 0
	BEGIN
		------------------
		COMMIT TRANSACTION
		------------------
		SET @iResult = 1
	END
	ELSE
	BEGIN
		--------------------
		ROLLBACK TRANSACTION
		--------------------
		SET @iResult = -1
	END

	RETURN @iResult
END


