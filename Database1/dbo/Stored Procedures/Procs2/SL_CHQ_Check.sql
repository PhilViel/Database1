/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_Check
Description         :	Procédure qui retournera les status disponibles pour chèques.
Valeurs de retours  :	Dataset :
					iCheckStatusID			INTEGER		ID unique de statut de chèque.
					vcStatusDescription		VARCHAR(50)	Description de statut.
Note                :	ADX0000710	IA	2005-08-24	Bernie MacIntyre			Création
			ADX0001058	IA	2006-08-01	Alain Quirion				Modification : Ajout du champ IsCompany
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_Check](
	@iCheckID int)
AS
BEGIN

	SET NOCOUNT ON

	SELECT
		C.iCheckID,
		C.iCheckStatusID,
		CS.vcStatusDescription,
		C.iCheckNumber,
		C.dtEmission,
		O.vcRefType,
		fCheckAmount = C.fAmount,
		bChangePayee = CAST(DH.bChangePayee AS BIT),
		vcReason = ISNULL(CH.vcReason,''),
		vcFirstName = ISNULL(C.vcFirstName,ISNULL(MH.FirstName,'')),
		vcLastName = ISNULL(C.vcLastName,ISNULL(MH.LastName,'')),
		vcAddress = ISNULL(C.vcAddress,ISNULL(MA.Address,'')),
		vcCity = ISNULL(C.vcCity,ISNULL(MA.City,'')),
		vcProvOrState = ISNULL(C.vcStateName,ISNULL(MA.StateName,'')),
		vcCountry = ISNULL(MCC.CountryName,ISNULL(MC.CountryName,'')),
		vcPostalCode = ISNULL(C.vcZipCode,ISNULL(MA.ZipCode,'')),
		vcAcctDescription = OD.vcDescription,
		vcOperDescription = O.vcDescription,
		vcAccount = OD.vcAccount,
		fDetailAmount = OD.fAmount,
		bIsCompany = MH.IsCompany
	FROM CHQ_Check C
	JOIN CHQ_CheckHistory CH ON C.iCheckID = CH.iCheckID
	JOIN CHQ_CheckOperationDetail COD ON C.iCheckID = COD.iCheckID 
	JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID 
	JOIN CHQ_Operation O ON O.iOperationID = OD.iOperationID
	JOIN CHQ_CheckStatus CS ON C.iCheckStatusID = CS.iCheckStatusID
	LEFT JOIN (
		SELECT iOperationID, bChangePayee = COUNT(iOperationID) - 1
		FROM CHQ_OperationPayee
		GROUP BY
			iOperationID
		) DH ON DH.iOperationID = O.iOperationID
	JOIN dbo.Mo_Human MH ON C.iPayeeID = MH.HumanID 
	LEFT JOIN dbo.Mo_Adr MA ON MH.AdrID = MA.AdrID 
	LEFT JOIN Mo_Country MC ON MA.CountryID = MC.CountryID
	LEFT JOIN Mo_Country MCC ON C.vcCountry = MCC.CountryID
	WHERE
		C.iCheckID = @iCheckID AND
		CH.iCheckHistoryID = (SELECT MAX(iCheckHistoryID) FROM CHQ_CheckHistory WHERE iCheckID = @iCheckID)

	RETURN 0

END


