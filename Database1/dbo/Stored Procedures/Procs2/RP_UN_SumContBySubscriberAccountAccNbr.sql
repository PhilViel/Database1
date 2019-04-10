/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_SumContBySubscriberAccountAccNbr
Description         :	Procédure stockée retournant les numéros de comptes valides à une date donnée pour le rapport 
								: Sommaire des contributions par compte souscripteur
Valeurs de retours  :	Dataset de données
									vcAccNbr1	VARCHAR(75)	Numéro de compte – Colonne : Épargne/ Épargne transitoire
									vcAccNbr2	VARCHAR(75)	Numéro de compte – Colonne : Épargne/ Épargne transitoire
									vcAccNbr3	VARCHAR(75)	Numéro de compte – Colonne : Frais
									vcAccNbr4	VARCHAR(75)	Numéro de compte – Colonne : Ass. bénéficiaire
									vcAccNbr5	VARCHAR(75)	Numéro de compte – Colonne : Ass. souscripteur
									vcAccNbr6	VARCHAR(75)	Numéro de compte – Colonne : Taxes 
									vcAccNbr7	VARCHAR(75)	Numéro de compte – Colonnes : Intérêts sur cotisation payés au promoteur et Intérêts sur cotisation reçus d’un promoteur - Compte : Intérêts reçus d’un promoteur
Note                :	ADX0001170	IA	2006-11-15	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_SumContBySubscriberAccountAccNbr] (
	@dtEnd DATETIME ) -- Date de fin du rapport 
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
					WHEN A.vcAccount = 'Épargne - Souscripteurs transitoire' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr3 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Gestion à payer - frais d''adhésion' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr4 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Gestion à payer - ass. bénéficiaires' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr5 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Gestion à payer - ass. souscription' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr6 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Taxe provinciale sur ass. à payer' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		vcAccNbr7 = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêts reçus d''un promoteur' THEN AN.vcAccountNumber
				ELSE ''
				END
				)
	FROM UN_Account A
	JOIN UN_AccountNumber AN ON AN.iAccountID = A.iAccountID
	WHERE @dtEnd BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
END

