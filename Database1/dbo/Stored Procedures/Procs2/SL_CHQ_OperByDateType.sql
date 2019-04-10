/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc

Nom                 : SL_CHQ_OperByDateType
Description         : Procédure qui retournera les opérations non-traitées, pour une date et un type d'opération.
Valeurs de retours  : Dataset :

   iOperationID   INTEGER       Identifiant unique de l’opération.
   iPayeeID       INTEGER       Identifiant unique du destinataire (payee) pour l’opération.
   bDestHistory   BIT           Indique qu’il existe un historique de changement de destinataire.
   bCheckHistory  BIT           Indique qu’il existe un historique de chèque pour cette opération.
   dtOperation    DATETIME      La date de l’opération.
   fAmount        DECIMAL(18,4) Le cumulatif des montants d’argent pour l’opération.
   vcDescription  VARCHAR(100)  La convention qui est la source de l’opération.
   vcFirstName    VARCHAR(50)   Prénom du destinataire.
   vcLastName     VARCHAR(50)   Nom de famille de la destinataire.
   vcRefType      VARCHAR(10)   Le type d’opération.

Exemple d’appel     : EXEC [dbo].[SL_CHQ_OperByDateType] '2010-06-07','PAE'

Historique des modifications:
               Date          Programmeur                        Description
               ------------  ---------------------------------- ---------------------------
NADX0000709 IA 2005-08-24    Bernie MacIntyre                   Création
ADX0000709  IA 2005-09-30    Bruno Lapointe                     Modification : Gestion des champs bDestHistory et bCheckHistory
ADX000-709  IA 5005-09-30    Bernie MacIntyre                   Modification : bDestHistory et bCheckHistory sont de type BIT
ADX0001058  IA 2006-08-01    Alain Quirion                      Modification : Renvoi bIsCompany
               2010-06-03    Danielle Côté                      ajout traitement fiducies distinctes par régime
****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_OperByDateType]
(
   @dtOperation DATETIME   -- La date des opérations
  ,@vcRefType VARCHAR(10)  -- Le type d'opération qui genère l'opération
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		O.iOperationID,
		P.iPayeeID,
		bDestHistory = 
			CASE
				WHEN DH.iOperationID IS NOT NULL THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END,
		bCheckHistory =
			CASE
				WHEN CH.iOperationID IS NOT NULL THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END,
		O.dtOperation,
		O.vcRefType,
		fAmount = SUM(OD.fAmount),
		O.vcDescription,
		vcFirstName = ISNULL(H.FirstName,''),
		vcLastName = ISNULL(H.LastName,''),
		bIsCompany = H.IsCompany,
      vcAccount = O.vcAccount,
		R.iID_Regroupement_Regime
	FROM CHQ_Operation O 
	JOIN CHQ_OperationDetail OD ON O.iOperationID = OD.iOperationID AND O.vcAccount = OD.vcAccount
	JOIN (
			SELECT
				iOperationID,
				iOperationPayeeID = MAX(iOperationPayeeID)
			FROM CHQ_OperationPayee OP
			WHERE iPayeeChangeAccepted <> 2
			GROUP BY iOperationID
		) V ON V.iOperationID = O.iOperationID
	JOIN CHQ_OperationPayee OP ON OP.iOperationPayeeID = V.iOperationPayeeID
	JOIN CHQ_Payee P ON OP.iPayeeID = P.iPayeeID
	JOIN dbo.Mo_Human H ON P.iPayeeID = H.HumanID
	LEFT JOIN (
		SELECT DISTINCT
			iOperationID
		FROM CHQ_OperationPayee
		GROUP BY
			iOperationID
		HAVING COUNT(iOperationPayeeID) > 1
		) DH ON DH.iOperationID = O.iOperationID
	LEFT JOIN (
		SELECT DISTINCT
			iOperationID
		FROM CHQ_OperationDetail OD
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		) CH ON CH.iOperationID = O.iOperationID
	LEFT JOIN (SELECT iID_Regroupement_Regime
                    ,vcCode_Compte_Comptable_Fiducie 
                FROM tblCONV_RegroupementsRegimes 
				   GROUP BY iID_Regroupement_Regime, vcCode_Compte_Comptable_Fiducie) R 
			 ON R.vcCode_Compte_Comptable_Fiducie = O.vcAccount
	-- La bonne date
	WHERE (O.dtOperation = @dtOperation)
		-- Le bon type
		AND (O.vcRefType = @vcRefType)
		-- L'opération n'a pas été annulé
		AND (O.bStatus = 0)
		-- L'opération n'est pas déjà dans un chèque (autre qu'une proposition de chèque refusé ou un chèque annulé)
		AND	(O.iOperationID NOT IN 
					(SELECT iOperationID FROM CHQ_OperationDetail WHERE iOperationDetailID IN 
						(SELECT iOperationDetailID FROM CHQ_CheckOperationDetail WHERE iCheckID IN 
							(SELECT iCheckID FROM CHQ_Check WHERE iCheckStatusID NOT IN (3,5))
						)
					)
				)
		AND OP.iPayeeChangeAccepted = 1
	GROUP BY
		O.iOperationID,
		P.iPayeeID,
		DH.iOperationID,
		CH.iOperationID,
		O.dtOperation,
		O.vcRefType,
		O.vcDescription,
		H.FirstName,
		H.LastName,
		H.IsCompany,
		O.vcAccount,
		R.vcCode_Compte_Comptable_Fiducie,
		R.iID_Regroupement_Regime
	HAVING SUM(OD.fAmount) > 0
	ORDER BY
		vcLastName,
		vcFirstName,
		P.iPayeeID,
      O.vcAccount,
		O.iOperationID
END


