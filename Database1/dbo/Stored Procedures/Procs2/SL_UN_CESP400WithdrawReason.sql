/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESP400WithdrawReason
Description         :	Procédure qui retourne les raisons de retrait de cotisations excédentaires.
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0001123	IA	2006-10-06	Alain Quirion Création
										2010-04-07  Pierre Paquet Ajout d'un TRI sur la description.
										2010-11-23	Pierre Paquet Ajout de la valeur bRaisonPCEE				
****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESP400WithdrawReason]
AS
	BEGIN
		SELECT 
			tiCESP400WithDrawReasonID,
			vcCESP400WithdrawReason,
			vcRightCode,		
			bRaisonPCEE
		FROM Un_CESP400WithdrawReason
		WHERE bIsCESP400WithdrawalReason = 1
		ORDER BY vcCESP400WithdrawReason
	END
