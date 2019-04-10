/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_ChangePayeeHistory
Description         :	Procédure qui retournera l'historique des changements de destinataire pour une opération précise.
Valeurs de retours  :	Dataset :
				vcRefType			VARCHAR(10)		Le type d'opération qui genère le chèque.
				dtOperation			DATETIME		La date de l'opération.
				vcDescription			VARCHAR(50)		La convention qui est la source de l'opération
				dtHistory			DATETIME		La date de historique sur le chèque.
				iStatus				INTEGER		Status de changement de destinataire (0=Proposé, 1=Accepté, 2=Refusé)
				vcReason			VARCHAR(50)		La raison de l'historique de chèque.
				vcFirstName			VARCHAR(35)		Le prénom du destinataire
				vcLastName			VARCHAR(50)		Le nom du destinataire
				vcAddress			VARCHAR(75)		L'adresse
				vcCity				VARCHAR(100)		La ville
				vcStateName			VARCHAR(75)		Province/état
				vcZipCode			VARCHAR(10)		Le code postal
				vcCountry			VARCHAR(75)		Le pays
Note                :	ADX0000710	IA	2005-10-17	Bernie MacIntyre			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_ChangePayeeHistory] (
	@iOperationID INTEGER ) -- Identifiant unique de l'opération, la convention qui est la source de l'opération.
AS BEGIN

SET NOCOUNT ON

SELECT
	O.iOperationID,
	O.vcRefType,
	O.dtOperation,
	O.vcDescription, 
	OP.iOperationPayeeID,
	OP.iPayeeID,
	'dtHistory' = OP.dtCreated,
	'iStatus' = OP.iPayeeChangeAccepted,
	OP.vcReason,
	H.HumanID,
	H.FirstName,
	H.LastName,
	A.AdrID,
	A.Address,
	A.City,
	A.StateName,
	A.ZipCode,
	C.CountryID,
	C.CountryName
FROM
	CHQ_Operation O JOIN
	CHQ_OperationPayee OP ON O.iOperationID = OP.iOperationID JOIN
	Mo_Human H ON OP.iPayeeID = H.HumanID LEFT JOIN
	Mo_Adr A ON H.AdrID = A.AdrID LEFT JOIN
	Mo_Country C ON A.CountryID = C.CountryID
WHERE
	O.iOperationID = @iOperationID
ORDER BY
	OP.iOperationPayeeID


END
