/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_SumCESPBySubscriberAccountAccNbr
Description         :	Procédure stockée retournant les numéros de comptes valides à une date donnée pour le rapport
								: Sommaire du PCEE par compte souscripteur
Valeurs de retours  :	Dataset de données
									vcAccNbr1	VARCHAR(75)	Numéro de compte – Colonne : SCEE
									vcAccNbr2	VARCHAR(75)	Numéro de compte – Colonne : SCEE+ 
									vcAccNbr3	VARCHAR(75)	Numéro de compte – Colonne : BEC
									vcAccNbr4	VARCHAR(75)	Numéro de compte – Colonne : Intérêts créditeurs - SCEE
									vcAccNbr5	VARCHAR(75)	Numéro de compte – Colonne : SCEE et SCEE+ reçu (TIN)
									vcAccNbr6	VARCHAR(75)	Numéro de compte – Colonne : BEC reçu (TIN) - Compte : Transfert in - BEC
									vcAccNbr7	VARCHAR(75)	Numéro de compte – Colonne : SCEE et SCEE+ payée (OUT)
									vcAccNbr8	VARCHAR(75)	Numéro de compte – Colonne : BEC payé (OUT)
									vciAccNbr9	VARCHAR(75)	Numéro de compte – Colonne : Intérêts SCEE, SCEE+ et BEC reçus (TIN)
									vcAccNbr10	VARCHAR(75)	Numéro de compte – Colonne : Intérêts SCEE, SCEE+ et BEC payés (OUT)
Note                :	ADX0001170	IA	2006-11-15	Bruno Lapointe		Création
						2010-02-10	Donald Huppé	Retourner seulement les 4 chiffres significatifs avec SUBSTRING 4,4
						
exec RP_UN_SumCESPBySubscriberAccountAccNbr '2010-02-10'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_SumCESPBySubscriberAccountAccNbr] (
	@dtEnd DATETIME ) -- Date de fin du rapport 
AS
BEGIN
	SELECT
		vcAccNbr1 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr2 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'SCEE+' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr3 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'BEC' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr4 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêt SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr5 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert in - SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr6 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert in - BEC' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr7 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr8 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out - BEC' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr9 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert in - intérêts SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4),
		vcAccNbr10 = 
			SUBSTRING(MAX(
				CASE 
					WHEN A.vcAccount = 'Transfert out- intérêts SCEE' THEN AN.vcAccountNumber
				ELSE ''
				END
				),4,4)
	FROM UN_Account A
	JOIN UN_AccountNumber AN ON AN.iAccountID = A.iAccountID
	WHERE @dtEnd BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
END

