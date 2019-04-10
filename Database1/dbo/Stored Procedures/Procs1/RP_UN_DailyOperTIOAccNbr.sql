/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_DailyOperTIOAccNbr 
Description         :	Renvoi les numéros de comptes pour les rapports d’opérations journalières TIO

Valeurs de retours  :	Dataset de données
							vcAccNbr1	VARCHAR(75)	Numéro de compte pour Épargne – souscripteur
							vcAccNbr2	VARCHAR(75)	Numéro de compte pour Frais – souscripteur
							vcAccNbr3	VARCHAR(75)	Numéro de compte pour Ass. Bénéficiaire
							vcAccNbr4	VARCHAR(75)	Numéro de compte pour Ass. Souscripteur
							vcAccNbr5	VARCHAR(75)	Numéro de compte pour Taxes
							vcAccNbr6	VARCHAR(75)	Numéro de compte pour Intérêts chargés au souscripteur
							vcAccNbr7	VARCHAR(75)	Numéro de compte pour Intérêts payé au promoteur
							vcAccNbr8	VARCHAR(75)	Numéro de compte pour Transfert SCEE payé (TIN)
							vcAccNbr9	VARCHAR(75)	Numéro de compte pour Transfert SCEE+ payé (TIN)
							vcAccNbr10	VARCHAR(75)	Numéro de compte pour Transfert BEC payé (TIN)
							vcAccNbr11	VARCHAR(75)	Numéro de compte pour Transfert Intérêts PCEE payés (TIN)
							vcAccNbr12	VARCHAR(75)	Numéro de compte pour Transfert SCEE payé (OUT)
							vcAccNbr13	VARCHAR(75)	Numéro de compte pour Transfert Intérêts SCEE payés (OUT)
							vcAccNbr14	VARCHAR(75)	Numéro de compte pour Transfert SCEE+ payé (OUT)
							vcAccNbr15	VARCHAR(75)	Numéro de compte pour Transfert Intérêts SCEE+ payés (OUT)
							vcAccNbr16	VARCHAR(75)	Numéro de compte pour Transfert BEC payé (OUT)
							vcAccNbr17	VARCHAR(75)	Numéro de compte pour Transfert Intérêts BEC payés (OUT)


Note                :	2009-09-11	Donald Huppé		Création

EXEC RP_UN_DailyOperTIOAccNbr '2009-09-03'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DailyOperTIOAccNbr]  (
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
					WHEN A.vcAccount = 'Gestion à payer - frais d''adhésion' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr3 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Gestion à payer - ass. bénéficiaires' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr4 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Gestion à payer - ass. souscription' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr5 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Taxe provinciale sur ass. à payer' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr6 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêts chargés aux Souscripteurs' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr7 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêts reçus d''un promoteur' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr8 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert in - SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr9 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert in - SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr10 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert in - BEC' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr11 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert in - intérêts SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),

		vcAccNbr12 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr13 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- intérêts SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr14 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr15 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- intérêts SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr16 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out - BEC' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr17 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out - intérêts BEC' THEN AN.vcAccountNumber
				ELSE ''
				END
				)

	FROM UN_Account A
	JOIN UN_AccountNumber AN ON AN.iAccountID = A.iAccountID
	WHERE @EndDate BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
END
