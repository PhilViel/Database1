/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_CESPTransferStatus
Description         :	Rapport des status des transferts.
Valeurs de retours  :	Dataset
				ExternalTransferStatusID,	Chaîne de 3 caractères identifiant le statut. 
								('30D' = 30 jours, '60D' = 60 jours, '90D' = 90 jours, 'ACC' = accepté)
				RegimeNumber,			Numéro d'enregistrement gouvernemental du plan de la convention de Fondation Universitas. 
				OtherContractNumber,
				OtherRegimeNumber,		Numéro d'enregistrement gouvernemental du plan de la convention du promoteur externe.
				Subscriber 			Prénom, Nom du souscripteur
				ConventionNo			Numéro de la convention
				fCESG				Montant de SCEE
				fCLB				Montant du BEC

Note                :						2006-09-11	Mireya Gonthier	Création										
								ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CESPTransferStatus] (
	@ExternalTransferStatusHistoryFileID INTEGER) -- ID unique du fichier de status des transferts
AS
BEGIN
	SELECT 
		H.ExternalTransferStatusID,
		H.RegimeNumber,
		H.OtherContractNumber,
		H.OtherRegimeNumber,
		Subscriber = S.FirstName+' '+S.LastName,
		C.ConventionNo,
		--Amount = ISNULL(GG.GovernmentGrantAmount,0)
		fCESG = ISNULL(GG.fCESG, 0)+ ISNULL(GG.fACESG,0),
		fCLB = ISNULL(GG.fCLB, 0)
	FROM Un_ExternalTransferStatusHistory H 
	JOIN Un_Oper O ON O.OperID = H.OperID
	JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
	LEFT JOIN (
		SELECT 
			OperID,
			--GovernmentGrantAmount = SUM(GovernmentGrantAmount)
			fCESG = SUM(fCESG),
			fCLB = SUM(fCLB),
			fACESG = SUM(fACESG)
		--FROM Un_GovernmentGrant
		FROM UN_CESP
		GROUP BY OperID
		) GG ON GG.OperID = O.OperID
	JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
	WHERE H.ExternalTransferStatusHistoryFileID = @ExternalTransferStatusHistoryFileID
	ORDER BY 
		H.ExternalTransferStatusID, 
		S.LastName, 
		S.FirstName, 
		C.ConventionNo  
END


