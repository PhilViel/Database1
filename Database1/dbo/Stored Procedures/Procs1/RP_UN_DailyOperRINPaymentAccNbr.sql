
/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_DailyOperRINPaymentAccNbr
Description         :	Renvoi les numéros de comptes pour les rapports d’opérations journalières de décaissement RIN.

Valeurs de retours  :	Dataset de données
							vcAccNbr1	VARCHAR(75)	Numéro de compte pour Épargne – souscripteur
							vcAccNbr2	VARCHAR(75)	Numéro de compte pour Frais – souscripteur							

Note                :	ADX0001326	IA	2006-11-15	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.RP_UN_DailyOperRINPaymentAccNbr (
	@EndDate DATETIME ) -- Date de fin du rapport 
AS
BEGIN
	SELECT
		vcAccNbr1 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Épargne - Souscripteurs' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr2 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Frais d''adhésion remboursés' THEN AN.vcAccountNumber
				ELSE ''
				END
				)
	FROM UN_Account A
	JOIN UN_AccountNumber AN ON AN.iAccountID = A.iAccountID
	WHERE @EndDate BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
END

