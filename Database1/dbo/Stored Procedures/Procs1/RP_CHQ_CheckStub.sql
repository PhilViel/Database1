/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	RP_CHQ_CheckStub
Description         :	Procédure qui retourne les données nécessaires pour le rapport des talons orphelins.
Valeurs de retours  :	Dataset :
									iCheckID				INTEGER			ID du cheque.
									iCheckNumer			INTEGER			Numéro du chèque
									dtEmission			DATETIME			La date du chèque.
									vcLastName			VARCHAR(50)		Nom de famille du destinataire du chèque.
									vcFirstName			VARCHAR(35)		Prénom du destinataire du chèque.
									vcAddress			VARCHAR(75)		Adresse du destinataire du chèque
									vcCity				VARCHAR(100)	La ville du destinataire du chèque.
									vcProvOrState		VARCHAR(75)		Le province du destinataire du chèque.
									vcCountry			VARCHAR(75)		Le pays du destinataire du chèque.
									vcPostalCode		VARCHAR(10)		Le code postal du destinataire du chèque.
									fAmount				DECIMAL(18,4)	Le montant du chèque.
									vcRefType			VARCHAR(10)		Le type des opérations liées au chèque.
									iOperationID		INTEGER			ID de l’opération
									vcDescription		VARCHAR(50)		Description de l’opération (Ex : U-20010101001).
									fOperationAmount	DECIMAL(18,4)	Le montant de l’opération chèque.
Note                :	ADX0000714	IA	2005-09-13	Bruno Lapointe		Création
								ADX0001058	IA	2006-08-01	Alain Quirion		Modification : Renvoit bIsCompany
								ADX0001098	IA	2006-09-11	Bruno Lapointe		Gestion des talons de chèques détaillés.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_CHQ_CheckStub](
	@iCheckBookID INTEGER, 		-- ID du chéquier
	@iStartCheckNumber INTEGER, 	-- Début de l’intervalle de numéro de chèque.
	@iEndCheckNumber INTEGER ) 	-- Fin de l’intervalle de numéro de chèque.
AS
BEGIN
	SELECT
		iCheckID, -- ID du cheque.
		iTemplateID, -- ID du template.
		iCheckNumber, -- Numéro du chèque
		dtEmission, -- La date du chèque.
		vcLastName, -- Nom de famille du destinataire du chèque.
		vcFirstName, -- 	Prénom du destinataire du chèque.
		vcAddress, -- Adresse du destinataire du chèque
		vcCity, -- La ville du destinataire du chèque.
		vcProvOrState, -- Le province du destinataire du chèque.
		vcCountry, -- Le pays du destinataire du chèque.
		vcPostalCode, -- Le code postal du destinataire du chèque.
		fAmount, -- Le montant du chèque.
		vcRefType, -- Le type des opérations liées au chèque.
		OperTypeDesc,
		iOperationID, -- ID de l’opération
		vcDescription, -- Description de l’opération (Ex : U-20010101001).
		fOperationAmount, -- Le montant de l’opération chèque.
		bIsCompany -- Indique s'il s'agit d'une compagnie.
	FROM (
		SELECT DISTINCT
			C.iCheckID, -- ID du cheque.
			C.iTemplateID, -- ID du template.
			C.iCheckNumber, -- Numéro du chèque
			C.dtEmission, -- La date du chèque.
			vcLastName = H.LastName, -- Nom de famille du destinataire du chèque.
			vcFirstName = H.FirstName, -- 	Prénom du destinataire du chèque.
			vcAddress = ISNULL(A.Address,''), -- Adresse du destinataire du chèque
			vcCity = ISNULL(A.City,''), -- La ville du destinataire du chèque.
			vcProvOrState = ISNULL(A.StateName,''), -- Le province du destinataire du chèque.
			vcCountry = ISNULL(Co.CountryName,''), -- Le pays du destinataire du chèque.
			vcPostalCode = ISNULL(A.ZipCode,''), -- Le code postal du destinataire du chèque.
			C.fAmount, -- Le montant du chèque.
			O.vcRefType, -- Le type des opérations liées au chèque.
			OT.OperTypeDesc,
			O.iOperationID, -- ID de l’opération
			O.vcDescription, -- Description de l’opération (Ex : U-20010101001).
			fOperationAmount = 
				CASE 
					WHEN C.bCheckStubDetailled = 0 THEN ISNULL(ODA.fAmount,0)
				ELSE 0
				END, -- Le montant de l’opération chèque.
			bIsCompany = H.IsCompany,
			vcTri = O.vcDescription+CAST(O.iOperationID AS VARCHAR(10))
		FROM CHQ_Check C
		JOIN CHQ_Payee P ON P.iPayeeID = C.iPayeeID
		JOIN dbo.Mo_Human H ON H.HumanID = P.iPayeeID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		LEFT JOIN Mo_Country Co ON Co.CountryID = A.CountryID
		JOIN CHQ_Template T ON T.iTemplateID = C.iTemplateID
		JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
		JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
		JOIN CHQ_Operation O ON O.iOperationID = OD.iOperationID
		JOIN Un_OperType OT ON OT.OperTypeID = O.vcRefType
		JOIN (
			SELECT
				ODA.iOperationID,
				fAmount = SUM(ODA.fAmount)
			FROM (
				SELECT DISTINCT OD.iOperationID
				FROM CHQ_Check C
				JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
				JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
				WHERE C.iCheckNumber BETWEEN @iStartCheckNumber AND @iEndCheckNumber
				) V
			JOIN CHQ_Operation O ON O.iOperationID = V.iOperationID
			JOIN CHQ_OperationDetail ODA ON ODA.iOperationID = O.iOperationID AND ODA.vcAccount = O.vcAccount
			GROUP BY ODA.iOperationID
			) ODA ON ODA.iOperationID = O.iOperationID
		WHERE C.iCheckStatusID = 4
			AND @iCheckBookID = T.iCheckBookID
			AND C.iCheckNumber BETWEEN @iStartCheckNumber AND @iEndCheckNumber
			AND C.iCheckStubDtlLines > T.iMaxStubDtlLines
		---------
		UNION ALL
		---------
		SELECT DISTINCT
			C.iCheckID, -- ID du cheque.
			C.iTemplateID, -- ID du template.
			C.iCheckNumber, -- Numéro du chèque
			C.dtEmission, -- La date du chèque.
			vcLastName = H.LastName, -- Nom de famille du destinataire du chèque.
			vcFirstName = H.FirstName, -- 	Prénom du destinataire du chèque.
			vcAddress = ISNULL(A.Address,''), -- Adresse du destinataire du chèque
			vcCity = ISNULL(A.City,''), -- La ville du destinataire du chèque.
			vcProvOrState = ISNULL(A.StateName,''), -- Le province du destinataire du chèque.
			vcCountry = ISNULL(Co.CountryName,''), -- Le pays du destinataire du chèque.
			vcPostalCode = ISNULL(A.ZipCode,''), -- Le code postal du destinataire du chèque.
			C.fAmount, -- Le montant du chèque.
			O.vcRefType, -- Le type des opérations liées au chèque.
			OT.OperTypeDesc,
			O.iOperationID, -- ID de l’opération
			vcDescription = '   '+ODA.vcClientDescription, -- Description de l’opération (Ex : U-20010101001).
			fOperationAmount = ODA.fAmount, -- Le montant de l’opération chèque.
			bIsCompany = H.IsCompany,
			vcTri = O.vcDescription+CAST(O.iOperationID AS VARCHAR(10))+ODA.vcClientDescription
		FROM CHQ_Check C
		JOIN CHQ_Payee P ON P.iPayeeID = C.iPayeeID
		JOIN dbo.Mo_Human H ON H.HumanID = P.iPayeeID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		LEFT JOIN Mo_Country Co ON Co.CountryID = A.CountryID
		JOIN CHQ_Template T ON T.iTemplateID = C.iTemplateID
		JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
		JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
		JOIN CHQ_Operation O ON O.iOperationID = OD.iOperationID
		JOIN Un_OperType OT ON OT.OperTypeID = RTRIM(O.vcRefType)
		JOIN (
			SELECT
				OD.iOperationID,
				A.vcClientDescription,
				fAmount = -SUM(OD.fAmount)
			FROM (
				SELECT DISTINCT OD.iOperationID
				FROM CHQ_Check C
				JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
				JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
				WHERE C.bCheckStubDetailled = 1
					AND C.iCheckNumber BETWEEN @iStartCheckNumber AND @iEndCheckNumber
				) V
			JOIN CHQ_Operation O ON O.iOperationID = V.iOperationID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = O.iOperationID
			JOIN Un_AccountNumber AN ON AN.vcAccountNumber = OD.vcAccount
			JOIN Un_Account A ON A.iAccountID = AN.iAccountID
			WHERE OD.vcAccount <> O.vcAccount
			GROUP BY 
				OD.iOperationID, 
				A.vcClientDescription
			) ODA ON ODA.iOperationID = O.iOperationID
		WHERE C.iCheckStatusID = 4
			AND @iCheckBookID = T.iCheckBookID
			AND C.iCheckNumber BETWEEN @iStartCheckNumber AND @iEndCheckNumber
			AND C.iCheckStubDtlLines > T.iMaxStubDtlLines
		) V
	ORDER BY 
		iCheckNumber, 
		vcTri
END


