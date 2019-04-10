/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_DailyOperPaymentAccNbr 
Description         :	Renvoi les numéros de comptes pour les rapports d’opérations journalières de décaissement.

Valeurs de retours  :	Dataset de données
							vcAccNbr1	VARCHAR(75)	Numéro de compte pour Épargne – souscripteur
							vcAccNbr2	VARCHAR(75)	Numéro de compte pour Frais – souscripteur
							vcAccNbr3	VARCHAR(75)	Numéro de compte pour Ass. Bénéficiaire
							vcAccNbr4	VARCHAR(75)	Numéro de compte pour Ass. Souscripteur
							vcAccNbr5	VARCHAR(75)	Numéro de compte pour Taxes
							vcAccNbr6	VARCHAR(75)	Numéro de compte pour Intérêts chargés au souscripteur
							vcAccNbr7	VARCHAR(75)	Numéro de compte pour Intérêts payé au promoteur
							vcAccNbr8	VARCHAR(75)	Numéro de compte pour Transfert SCEE payé (OUT)
							vcAccNbr9	VARCHAR(75)	Numéro de compte pour Transfert Intérêts SCEE payés (OUT)
							vcAccNbr10	VARCHAR(75)	Numéro de compte pour Transfert SCEE+ payé (OUT)
							vcAccNbr11	VARCHAR(75)	Numéro de compte pour Transfert Intérêts SCEE+ payés (OUT)
							vcAccNbr12	VARCHAR(75)	Numéro de compte pour Transfert BEC payé (OUT)
							vcAccNbr13	VARCHAR(75)	Numéro de compte pour Transfert Intérêts BEC payés (OUT)

Note                :	ADX0001326	IA	2006-11-15	Alain Quirion	Création
										2010-02-24	Donald Huppé	Retourner les 4 chiffres significatif

exec RP_UN_DailyOperPaymentAccNbr '2010-02-25'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DailyOperPaymentAccNbr]  (
	@EndDate DATETIME ) -- Date de fin du rapport 
AS
BEGIN
	SELECT
		vcAccNbr1 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Épargne - Souscripteurs' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr2 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Gestion à payer - frais d''adhésion' THEN AN.vcAccountNumber 
				ELSE ''
				END
				),4,4),
		vcAccNbr3 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Gestion à payer - ass. bénéficiaires' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr4 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Gestion à payer - ass. souscription' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr5 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Taxe provinciale sur ass. à payer' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr6 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêts chargés aux Souscripteurs' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr7 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêts reçus d''un promoteur' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr8 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr9 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- intérêts SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr10 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr11 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- intérêts SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr12 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out - BEC' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr13 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out - intérêts BEC' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4)
	FROM UN_Account A
	JOIN UN_AccountNumber AN ON AN.iAccountID = A.iAccountID
	WHERE @EndDate BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
END
