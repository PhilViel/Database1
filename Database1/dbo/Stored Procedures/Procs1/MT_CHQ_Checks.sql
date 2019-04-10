/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	MT_CHQ_Checks
Description         :	Procédure qui retournera les status disponibles pour les chèques.
Valeurs de retours  :	Dataset :
									iCheckStatusID			INTEGER		ID unique de statut de chèque.
									vcStatusDescription		VARCHAR(50)		Description de statut.
Note                :	ADX0000710	IA	2006-02-15	Pierre-Michel Bussière			Création
			ADX0002097	BR	2006-09-25	Alain	Quirion	Modification	Utilisation d'un blob au lieur d'un varchar(8000)
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[MT_CHQ_Checks](
	@iBlobID INTEGER) -- ID du blob contenant la liste des ID de chèque séparer par de virgule
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @iReturnValue INTEGER

	SET @iReturnValue = 1

	CREATE TABLE #tOrderCheck
	(
		iOrder INTEGER IDENTITY(1, 1) NOT NULL,
		iCheckID INTEGER NOT NULL
	)

	IF @@ERROR <> 0
		SET @iReturnValue = -1

	IF @iReturnValue > 0
	BEGIN
		INSERT INTO #tOrderCheck (iCheckID)
		SELECT iVal
		FROM dbo.FN_CRI_BlobToIntegerTable(@iBlobID) 

		IF @@ERROR <> 0
			SET @iReturnValue = -1
	END

	IF @iReturnValue > 0
	BEGIN
		SELECT
			C.iCheckID,
			C.iCheckStatusID,
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
			fDetailAmount = OD.fAmount
		FROM CHQ_Check C
		JOIN #tOrderCheck tC ON tC.iCheckID = C.iCheckID
		JOIN CHQ_CheckHistory CH ON C.iCheckID = CH.iCheckID
		JOIN CHQ_CheckOperationDetail COD ON C.iCheckID = COD.iCheckID 
		JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID 
		JOIN CHQ_Operation O ON O.iOperationID = OD.iOperationID
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
			CH.iCheckHistoryID = (SELECT MAX(iCheckHistoryID) FROM CHQ_CheckHistory WHERE iCheckID = C.iCheckID)
		ORDER BY tC.iOrder
	END

	IF	EXISTS(SELECT *
			FROM tempdb..sysobjects
			WHERE xtype = 'U' AND [name] LIKE '#tOrderCheck%')
		DROP TABLE #tOrderCheck 

	RETURN @iReturnValue

END


