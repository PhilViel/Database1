/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	DL_CRQ_Dep
Description         :	Procédure de suppression de département.
Valeurs de retours  :	@ReturnValue :
									> 0 : La suppression a réussie.  La valeur de retour correspond au DepID du département
											supprimée
									<= 0: La suppression a échouée.
Note                :	ADX0000730	IA	2005-06-13	Bruno Lapointe		Création
										2014-04-30	Maxime Martel		Suppression dans tblGENE_Adresse au lieu de 
																		Mo_Adr
*********************************************************************************************************************/
CREATE  PROCEDURE [dbo].[DL_CRQ_Dep] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@DepID INTEGER ) -- ID du département à supprimer.
AS
BEGIN
	DECLARE
		@AdrID MoIDOption,
		@iResultID INTEGER

	SET @iResultID = @DepID

	IF @DepID <> 0
	BEGIN
		SELECT @AdrID = AdrID
		FROM Mo_Dep
		WHERE DepID = @DepID

		DELETE
		FROM Mo_Dep
		WHERE DepID = @DepID

		IF @@ERROR <> 0
			SET @iResultID = -1

		IF @iResultID > 0
		BEGIN
			DELETE tblGENE_Adresse
			FROM tblGENE_Adresse A
			WHERE A.iID_Source = @DepID
				AND A.cType_Source = 'C'
				AND NOT EXISTS (
						SELECT D.AdrID
						FROM Mo_Dep D
						WHERE D.AdrID = A.iID_Adresse )

			IF @@ERROR <> 0
				SET @iResultID = -2
		END
	END
	RETURN @iResultID
END
