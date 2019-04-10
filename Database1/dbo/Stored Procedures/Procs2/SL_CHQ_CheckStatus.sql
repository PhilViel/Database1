/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_CheckStatus
Description         :	Procédure qui retournera les status disponibles pour chèques.
Valeurs de retours  :	Dataset :
									iCheckStatusID			INTEGER		ID unique de statut de chèque.
									vcStatusDescription		VARCHAR(50)		Description de statut.
Note                :	ADX0000710	IA	2005-08-24	Bernie MacIntyre			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_CheckStatus]
AS BEGIN

	SET NOCOUNT ON

	SELECT 
		iCheckStatusID, -- ID unique de statut de chèque.
		vcStatusDescription -- Description de statut.
	FROM CHQ_CheckStatus
	WHERE bStatusAvailable = 1 -- Ne sélectionne que les statuts qui sont disponibles.
END
