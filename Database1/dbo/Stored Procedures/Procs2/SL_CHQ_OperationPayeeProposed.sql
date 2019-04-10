/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_OperationPayeeProposed
Description         :	Procédure qui retournera la liste des propositions de changement de destinataire.
Valeurs de retours  :	Dataset :
									iOperationPayeeID		INTEGER			Identificateur du changement de destinataire.
									iPayeeChangeAccepted	INTEGER			Status du changement de destinataire.
									iOperationID			INTEGER			ID de l'opération du module des chèques
									dtOperation				DATETIME			La date de l'opération.
									vcRefType				VARCHAR(10)		Le type d’opération qui genère le chèque.
									vcDescription			VARCHAR(75)		La convention qui est la source de l’opération.
									vcReason					VARCHAR(75)		La raison de changement de destinataire.
									vcLastNameBef			VARCHAR(50)		Nom de famille de la destinataire originale.
									vcFirstNameBef			VARCHAR(35)		Prénom de la destinataire originale.
									vcAddressBef			VARCHAR(75)		Adresse de la destinataire originale
									vcCityBef				VARCHAR(100)	La ville de la destinataire originale.
									vcProvOrStateBef		VARCHAR(75)		Le province de la destinataire originale.
									vcCountryBef			VARCHAR(75)		Le pays de la destinataire originale.
									vcPostalCodeBef		VARCHAR(10)		Le code postal de la destinataire originale.
									vcLastNameAft			VARCHAR(50)		Nom de famille de la nouvelle destinataire.
									vcFirstNameAft			VARCHAR(35)		Prénom de la nouvelle destinataire.
									vcAddressAft			VARCHAR(75)		Adresse de la nouvelle destinataire
									vcCityAft				VARCHAR(100)	La ville de la nouvelle destinataire.
									vcProvOrStateAft		VARCHAR(75)		Le province de la nouvelle destinataire.
									vcCountryAft 			VARCHAR(75)		Le pays de la nouvelle destinataire.
									vcPostalCodeAft		VARCHAR(10)		Le code postal de la nouvelle destinataire.
Note                :	ADX0000714	IA	2005-09-12	Bruno Lapointe		Création
								ADX0001975	BR	2006-06-13	Bruno Lapointe		Ne pas considéré les opérations annulées ou  
																							supprimées (CHQ_Operation.bStatus <> 0).
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_OperationPayeeProposed] (
	@iConnectID INTEGER ) -- ID de l’usager qui a lancé la procédure.	
AS
BEGIN

	SET NOCOUNT ON

	SELECT 
		OP.iOperationPayeeID, -- Identificateur du cheque.
		OP.iPayeeChangeAccepted, -- Status du changement de destinataire
		O.iOperationID, -- ID de l'opération du module des chèques
		O.dtOperation, -- La date de l'opération
		O.vcRefType, -- Le type d’opération qui genère le chèque.
		O.vcDescription, -- La convention qui est la source de l’opération.
		OP.vcReason, -- La raison de changement de destinataire.
		vcLastNameBef = HB.LastName, -- Nom de famille de la destinataire originale.
		vcFirstNameBef = HB.FirstName, -- Prénom de la destinataire originale.
		vcAddressBef = ISNULL(AB.Address,''), -- Adresse de la destinataire originale
		vcCityBef = ISNULL(AB.City,''), -- La ville de la destinataire originale.
		vcProvOrStateBef = ISNULL(AB.StateName,''), -- Le province de la destinataire originale.
		vcCountryBef = ISNULL(CB.CountryName,''), -- Le pays de la destinataire originale.
		vcPostalCodeBef = ISNULL(AB.ZipCode,''), -- Le code postal de la destinataire originale.
		vcLastNameAft = H.LastName, -- Nom de famille de la nouvelle destinataire.
		vcFirstNameAft = H.FirstName, -- Prénom de la nouvelle destinataire.
		vcAddressAft = ISNULL(A.Address,''), -- Adresse de la nouvelle destinataire
		vcCityAft = ISNULL(A.City,''), -- La ville de la nouvelle destinataire.
		vcProvOrStateAft = ISNULL(A.StateName,''), -- Le province de la nouvelle destinataire.
		vcCountryAft = ISNULL(C.CountryName,''), -- Le pays de la nouvelle destinataire.
		vcPostalCodeAft = ISNULL(A.ZipCode,'') -- Le code postal de la nouvelle destinataire.
	INTO #tOperationPayeeProposed
	FROM CHQ_OperationPayee OP
	JOIN CHQ_Operation O ON O.iOperationID = OP.iOperationID
	JOIN CHQ_Payee P ON P.iPayeeID = OP.iPayeeID
	JOIN dbo.Mo_Human H ON H.HumanID = P.iPayeeID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
	JOIN ( -- Retourne le dernier changement de destinataire accepté d'un opération
		SELECT
			OP1.iOperationID, -- ID de l'opération
			iOperationPayeeIDBef = MAX(OP1.iOperationPayeeID) -- ID du dernier changement de destinataire accepté
		FROM CHQ_OperationPayee OP1
		JOIN CHQ_OperationPayee OP2 ON OP1.iOperationID = OP2.iOperationID AND OP2.iPayeeChangeAccepted = 0
		WHERE OP1.iPayeeChangeAccepted = 1 -- Changement de destinataire accepté seulement
		GROUP BY OP1.iOperationID
			) Bef ON Bef.iOperationID = O.iOperationID
	JOIN CHQ_OperationPayee OPB ON OPB.iOperationPayeeID = Bef.iOperationPayeeIDBef
	JOIN CHQ_Payee PB ON PB.iPayeeID = OPB.iPayeeID
	JOIN dbo.Mo_Human HB ON HB.HumanID = PB.iPayeeID
	LEFT JOIN dbo.Mo_Adr AB ON AB.AdrID = HB.AdrID
	LEFT JOIN Mo_Country CB ON CB.CountryID = AB.CountryID
	WHERE OP.iPayeeChangeAccepted = 0 -- Changement de destinataire proposé seulement.
		AND O.bStatus = 0
	ORDER BY
		O.dtOperation,
		O.vcRefType,
		O.vcDescription

	-- Supprime les barrures désuettes ou encore ceux qui existe déjà pour la même connexion.
	EXECUTE TT_CHQ_UnLockedOperation @iConnectID

	-- Barre les enregistrements retournés.
	INSERT INTO CHQ_OperationLocked (
			iOperationID,
			dtLocked,
			iConnectID )
		SELECT
			OP.iOperationID,
			GETDATE(),
			@iConnectID
		FROM #tOperationPayeeProposed P
		JOIN CHQ_OperationPayee OP ON OP.iOperationPayeeID = P.iOperationPayeeID

	-- Retroune le tout.
	SELECT *
	FROM #tOperationPayeeProposed

END


