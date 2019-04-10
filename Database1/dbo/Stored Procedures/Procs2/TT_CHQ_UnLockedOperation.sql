/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TT_CHQ_UnLockedOperation
Description         :	Procédure qui enlève les barrures sur les opérations pour une connexion usager ainsi que les
								barrures passées date.
Valeurs de retours  :	@ReturnValue :
									> 0 : Le traitement a réussi.
									< 0 : Le traitement a échoué.
Note                :	ADX0000714	IA	2005-09-28	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_CHQ_UnLockedOperation] (
	@iConnectID	INTEGER) -- ID unique de la connexion.
AS
BEGIN
	DELETE 
	FROM CHQ_OperationLocked
	WHERE iConnectID = @iConnectID -- Barrure de la connexion en question
		OR dbo.FN_CRQ_DateNoTime(dtLocked) < dbo.FN_CRQ_DateNoTime(GETDATE()) -- Barrures passées date
		OR iOperationID IN ( -- Barrure d'une autre connexion du même usager sur le même poste
				SELECT L.iOperationID
				FROM Mo_Connect C
				JOIN Mo_Connect C2 ON C2.ConnectID <> C.ConnectID AND C.UserID = C2.UserID AND C.StationName = C2.StationName
				JOIN CHQ_OperationLocked L ON L.iConnectID = C2.ConnectID
				WHERE C.ConnectID = @iConnectID
				)
END
