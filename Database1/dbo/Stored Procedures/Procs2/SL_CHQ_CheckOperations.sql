/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_CheckOperations
Description         :	Procédure qui retournera les opérations combinées dans une seule écriture pour un chèque.
Valeurs de retours  :	Dataset :
				iCheckNumber		INTEGER		Le numéro de chèque tel qu'imprimé sur le chèque.
				dtEmission		DATETIME		La date de l'émission du chèque.
				vcRefType		VARCHAR(10)		Le type d'opération qui genère le chèque
				fAmount			DECIMAL(18,4)		Le montant du chèque.
				vcDescription		VARCHAR(50)		La convention qui est la source de l'opération.
				bChangePayee		BIT			Valeur qui indique qu'un opération a un changement de destinataire.
				vcAccount		VARCHAR(50)		La description du compte comptable.
				vcAccountNumber	VARCHAR(50)		Le numéro de compte comptable.
				fDebit			DECIMAL(18,4)		Le montant à débiter.
				fCredit			DECIMAL(18,4)		Le montant à créditer.

Note                :	ADX0000710	IA	2005-09-12	Bernie MacIntyre			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_CheckOperations] (
	@iCheckID INTEGER ) -- Identifiant unique du chèque
AS BEGIN

SET NOCOUNT ON

	SELECT
		C.iCheckNumber,
		C.dtEmission,
		O.iOperationID,
		O.vcRefType,
		fCheckAmount = C.fAmount,
		O.vcDescription,
		vcAccount = OD.vcDescription,
		DH.bChangePayee,
		vcAccountNumber = OD.vcAccount,
		fDetailAmount = OD.fAmount
	FROM CHQ_Check C
	JOIN CHQ_CheckOperationDetail COD ON C.iCheckID = COD.iCheckID
	JOIN CHQ_OperationDetail OD ON COD.iOperationDetailID = OD.iOperationDetailID
	JOIN CHQ_Operation O ON OD.iOperationID = O.iOperationID
	LEFT JOIN (
		SELECT iOperationID, bChangePayee = CAST(COUNT(iOperationID) - 1 AS BIT)
		FROM CHQ_OperationPayee
		GROUP BY
			iOperationID
		) DH ON DH.iOperationID = O.iOperationID
	WHERE
		C.iCheckID = @iCheckID
	ORDER BY
		O.iOperationID,
		O.vcDescription,
		OD.fAmount
END
