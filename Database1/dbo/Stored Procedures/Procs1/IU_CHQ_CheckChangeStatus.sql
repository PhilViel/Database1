/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	IU_CHQ_CheckChangeStatus
Description         :	Procédure qui changera le statut du ou des chèques, selon les paramètres.
Valeurs de retours  :	@ReturnValue :
									> 0 : L’opération a réussie.
									< 0 : L’opération a échouée.
Note                :	ADX0000714	IA	2005-09-12	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_CHQ_CheckChangeStatus] (
	@iConnectID INTEGER, -- ID de connexion de l'usager
	@iBlobID INTEGER,	-- ID du blob qui contient les iOperationPayeeID séparés par des virgules des changements de 
							-- destinataires qu’il faut changer à ce statut.
	@iCheckStatusID INTEGER )	-- Le chèque que doit avoir les chèques passés en paramètre. (1=Proposé, 2=Proposition 
										-- acceptée, 3=Proposition refusée, 4=Imprimé, 5=Annulé, 6=Concilié)
AS
BEGIN

	SET NOCOUNT ON

	DECLARE
		@iResult INTEGER

	-----------------
	BEGIN TRANSACTION
	-----------------

	SET @iResult = 1

	UPDATE CHQ_Check
	SET iCheckStatusID = @iCheckStatusID
	FROM CHQ_Check
	JOIN dbo.FN_CRI_BlobToIntegerTable(@iBlobID) T ON T.iVal = CHQ_Check.iCheckID

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		INSERT INTO CHQ_CheckHistory (
				iCheckID,
				iCheckStatusID,
				dtHistory,
				iConnectID,
				vcReason )
			SELECT
				T.iVal,
				@iCheckStatusID,
				GETDATE(),
				@iConnectID,
				CASE @iCheckStatusID
					WHEN 1 THEN 'Destinataire : '+ CASE H.IsCompany
										WHEN 0 THEN ISNULL(H.LastName,'') + ', '+ISNULL(H.FirstName,'')
										WHEN 1 THEN ISNULL(H.LastName,'')
									END
					WHEN 2 THEN 'Par : '+U.LoginNameID
					WHEN 3 THEN 'Par : '+U.LoginNameID
					WHEN 4 THEN 'Destinataire : '+ CASE H.IsCompany
										WHEN 0 THEN ISNULL(H.LastName,'') + ', '+ISNULL(H.FirstName,'')
										WHEN 1 THEN ISNULL(H.LastName,'')
									END
					WHEN 5 THEN 'Erreur d’impression'
				ELSE ''
				END
			FROM dbo.FN_CRI_BlobToIntegerTable(@iBlobID) T
			JOIN Mo_Connect Co ON Co.ConnectID = @iConnectID
			JOIN Mo_User U ON U.UserID = Co.UserID
			JOIN CHQ_Check C ON C.iCheckID = T.iVal
			LEFT JOIN dbo.Mo_Human H ON H.HumanID = C.iPayeeID

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN(@iResult)

END


