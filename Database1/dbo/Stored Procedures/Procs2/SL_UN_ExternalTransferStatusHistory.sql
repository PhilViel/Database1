/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	SL_UN_ExternalTransferStatusHistory
Description         :	Renvoi l'historique des status pour une opération TIN OUT.
Valeurs de retours  :	Dataset
				ExternalTransferStatusHistoryID		ID unique de l'enregistrement d'historique de statut de transfert
				OperID					ID unique de l'opération
				ExternalTransferStatusID,		Chaîne de 3 caractères identifiant le statut. 
									('30D' = 30 jours, '60D' = 60 jours, '90D' = 90 jours,
									 'ACC' = accepté)
				RegimeNumber,				Numéro d'enregistrement gouvernemental du plan de la 
									convention de Fondation Universitas. 
				OtherContractNumber,
				OtherRegimeNumber,			Numéro d'enregistrement gouvernemental du plan de la 
									convention du promoteur externe.
				ExternalTransferStatushistoryFileID	ID unique du fichier d'historique de transfert 
									(Un_ExternalTransferStatusHistoryFile). ID unique du 
									fichier d'historique de transfert 
									(Un_ExternalTransferStatusHistoryFile). 
				ExternalTransferStatusHistoryFileName	Nom du fichier. Correspond au nom du fichier Excel. 
				ExterneTransferStatusHistoriFileDate	Date de réception du fichier Excel. 

Note                :						2006-09-11	Mireya Gonthier		Création										
****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ExternalTransferStatusHistory] (
	@OperID MoID ) -- Id unique de l'opération
AS
BEGIN
	SELECT 
		H.ExternalTransferStatusHistoryID,
		H.OperID,
		H.ExternalTransferStatusID,
		H.RegimeNumber,
		H.OtherContractNumber,
		H.OtherRegimeNumber,
		F.ExternalTransferStatusHistoryFileID,
		F.ExternalTransferStatusHistoryFileName,
		F.ExternalTransferStatusHistoryFileDate,
		C.ConventionNo
	FROM Un_ExternalTransferStatusHistory H
	JOIN Un_ExternalTransferStatusHistoryFile F ON H.ExternalTransferStatusHistoryFileID = F.ExternalTransferStatusHistoryFileID
	JOIN Un_Cotisation CT ON CT.OperID = H.OperID
	JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	WHERE H.OperID = @OperID 
	ORDER BY F.ExternalTransferStatusHistoryFileDate DESC
END


