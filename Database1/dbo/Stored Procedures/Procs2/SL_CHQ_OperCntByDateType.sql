/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc

Nom                 : SL_CHQ_OperCntByDateType
Description         : Procédure qui retournera le nombre d'opérations non-traitées, par date et par type
                      d'opération avec tri de date en ordre décroissant.
Valeurs de retours  :	Dataset :
									dtOperation		DATETIME			La date de l'opération.
									vcRefType		VARCHAR(10)		Le type d'opération qui genère le chèque.
									iOperCnt			INTEGER			Le nombre d'opérations toujours disponibles pour chèques.

Historique des modifications:
               Date          Programmeur                        Description
               ------------  ---------------------------------- ---------------------------
ADX0000709  IA 2005-08-24    Bernie MacIntyre                   Création
               2010-06-03    Danielle Côté                      ajout traitement fiducies distinctes par régime
                                                                (AND O.dtOperation > '2010-01-01')
****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_OperCntByDateType]
AS
BEGIN

   SET NOCOUNT ON

   SELECT O.dtOperation -- La date de l'opération
         ,O.vcRefType   -- Le type d'opération qui genère le chèque
         ,'iOperCnt' = CAST(COUNT(O.vcRefType) AS INT) -- Le nombre d'opérations toujours disponibles pour chèques
     FROM CHQ_Operation O
     JOIN (SELECT iOperationID
                 ,iOperationPayeeID = MAX(iOperationPayeeID)
             FROM CHQ_OperationPayee OP
            WHERE iPayeeChangeAccepted <> 2
            GROUP BY iOperationID
          ) V ON V.iOperationID = O.iOperationID
     JOIN CHQ_OperationPayee OP ON OP.iOperationPayeeID = V.iOperationPayeeID
    WHERE O.bStatus = 0 -- L'opération n'a pas été annulé
      --  L'opération a au moins un détail
      AND O.iOperationID IN (SELECT DISTINCT iOperationID FROM CHQ_OperationDetail)
      --  L'opération n'est pas déjà dans un chèque (autre qu'une proposition de chèque refusé ou un chèque annulé)
      AND (O.iOperationID NOT IN 
             (SELECT iOperationID FROM CHQ_OperationDetail WHERE iOperationDetailID IN 
                (SELECT iOperationDetailID FROM CHQ_CheckOperationDetail WHERE iCheckID IN 
                   (SELECT iCheckID FROM CHQ_Check WHERE iCheckStatusID NOT IN (3,5))
                    AND fAmount > 0)
             )
          )
      AND OP.iPayeeChangeAccepted = 1 -- Pas de changement de destinataire en proposition
      AND O.dtOperation > '2010-07-01'
    GROUP BY O.dtOperation
            ,O.vcRefType
    ORDER BY O.dtOperation DESC
            ,O.vcRefType

END
