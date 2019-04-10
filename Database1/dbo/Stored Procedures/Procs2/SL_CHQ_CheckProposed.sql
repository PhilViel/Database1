/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_CheckProposed
Description         :	Procédure qui retournera la liste des propositions des chèques.
Valeurs de retours  :	Dataset :
									iCheckID			INTEGER			ID du cheque.
									iCheckStatusID	INTEGER			Statut du chèque (1=Proposé, 2=Proposition acceptée, 
																			3=Proposition refusée, 4=Imprimé, 5=Annulé, 6=Concilié)
									dtEmission		DATETIME			La date du chèque.
									vcRefType		VARCHAR(10)		Le type des opérations liées au chèque.
									vcLastName		VARCHAR(50)		Nom de famille du destinataire du chèque.
									vcFirstName		VARCHAR(35)		Prénom du destinataire du chèque.
									vcAddress		VARCHAR(75)		Adresse du destinataire du chèque
									vcCity			VARCHAR(100)	La ville du destinataire du chèque.
									vcProvOrState	VARCHAR(75)		Le province du destinataire du chèque.
									vcCountry		VARCHAR(75)		Le pays du destinataire du chèque.
									vcPostalCode	VARCHAR(10)		Le code postal du destinataire du chèque.
									fAmount			DECIMAL(18,4)	Le montant du chèque.
Note                :	ADX0000714	IA	2005-09-12	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_CheckProposed] 
AS
BEGIN

	SET NOCOUNT ON

	SELECT 
		C.iCheckID, -- ID du cheque.
		CH.iCheckStatusID, -- Statut du chèque (1=Proposé, 2=Proposition acceptée, 3=Proposition refusée, 4=Imprimé, 5=Annulé, 6=Concilié)
		C.dtEmission, -- La date du chèque.
		O.vcRefType, -- Le type des opérations liées au chèque.
		vcLastName = H.LastName, -- Nom de famille du destinataire du chèque.
		vcFirstName = H.FirstName, -- 	Prénom du destinataire du chèque.
		vcAddress = ISNULL(A.Address,''), -- Adresse du destinataire du chèque
		vcCity = ISNULL(A.City,''), -- La ville du destinataire du chèque.
		vcProvOrState = ISNULL(A.StateName,''), -- Le province du destinataire du chèque.
		vcCountry = ISNULL(Co.CountryName,''), -- Le pays du destinataire du chèque.
		vcPostalCode = ISNULL(A.ZipCode,''), -- Le code postal du destinataire du chèque.
		C.fAmount -- Le montant du chèque.
	FROM CHQ_Check C
	JOIN ( -- Retourne le type des opérations liées à un chèque
		SELECT 
			C.iCheckID, -- ID du chèque
			vcRefType = MAX(O.vcRefType) -- Type des opérations de ce chèque
		FROM CHQ_Check C
		JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
		JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
		JOIN CHQ_Operation O ON O.iOperationID = OD.iOperationID
		GROUP BY C.iCheckID
		) O ON O.iCheckID = C.iCheckID
	JOIN CHQ_Payee P ON P.iPayeeID = C.iPayeeID
	JOIN dbo.Mo_Human H ON H.HumanID = P.iPayeeID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Mo_Country Co ON Co.CountryID = A.CountryID
	JOIN ( -- Trouve le dernier historique de statut de chaque chèque
		SELECT
			CH.iCheckID, -- ID du chèque
			iCheckHistoryID = MAX(CH.iCheckHistoryID) -- Dernier statut de ce chèque
		FROM CHQ_CheckHistory CH
		GROUP BY CH.iCheckID
		) MCH ON MCH.iCheckID = C.iCheckID
	JOIN CHQ_CheckHistory CH ON CH.iCheckHistoryID = MCH.iCheckHistoryID 
	WHERE CH.iCheckStatusID = 1 -- Chèque proposé seulement.
	ORDER BY
		C.dtEmission,
		O.vcRefType,
		H.LastName,
		H.FirstName

END


