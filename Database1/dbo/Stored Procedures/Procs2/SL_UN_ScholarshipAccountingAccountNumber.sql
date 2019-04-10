/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	SL_UN_ScholarshipAccountingAccountNumber
Description         :	Numéro de compte G/L pour le rapport de comptabilité des bourses
Valeurs de retours  :	Dataset de données
		Avance sur bourse		Numéro de compte - Avance sur bourse 
						COL : Avance
		Bourses d''études versées		Numéro de compte – Bourse d’études versées 
						COL : Bourse d’études versées
		Intérêts versés (Bourse individuel)	Numéro de compte – Intérêts versés (Bourse individuel) 
						COL : Intérêts versés (individuel)
		SCEE versée (Collectif)		Numéro de compte – SCEE Versée (Collectif) 
						COL1 : SCEE versée collectif / individuel 
						COL2 : SCEE+ versée collectif / individuel
		SCEE versée (Individuel)		Numéro de compte – SCEE Versée (individuel) 
						COL1 : SCEE versée collectif / individuel
						COL2 : SCEE+ versée collectif / individuel
		BEC versée (Collectif)		Numéro de compte - BEC versée (collectif) 
						COL : Bec versé collectif / individuel
		BEC versée (Individuel)		Numéro de compte - BEC versée (individuel) 
						COL : BEC versé collectif / individuel
		Intérêt SCEE versée (Collectif)		Numéro de compte - Intérêts SCEE versée (collectif) 
						COL1 : Intérêts SCEE versés collectif / individuel 
						COL2 : Intérêts SCEE+ versés collectif / individuel
		Intérêt SCEE versée (Individuel)	Numéro de compte - Intérêt SCEE versée individuel 
						COL : Intérêts SCEE versés collectif / individuel 
						COL2 : Intérêts SCEE+ versés collectif / individuel
		Intérêt BEC versée (Collectif)	Numéro de compte – Intérêt BEC versée (Collectif) 
						COL : Intérêts BEC versés collectif / individuel
		Intérêt BEC versée (Individuel)		Numéro de compte – Intérêt BEC versée (Individuel) 
						COL : Intérêts BEC versés collectif / individuel
		Intérêts reçus d''un promoteur		Numéro de compte – Intérêt reçus d’un promoteur  
						COL : Intérêts reçus d’un promoteur versés
		Intérêts sur RI reporté		Numéro de compte – Intérêt sur RI reporté 
						COL : Intérêts sur RI versés
Note                :	ADX0001112	IA	2006-10-18	Bruno Lapointe		Création
								ADX0002439	BR	2007-05-21	Bruno Lapointe		Changé le compte "Intérêt reçus d’un promoteur" 
																							pour "Intérêt versé sur intérêt reçu d''un promoteur"
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ScholarshipAccountingAccountNumber] (
	@EndDate DATETIME) -- Date de fin de la période traitée par le rapport. 
AS
BEGIN
	SELECT
		'Avance sur bourse' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Avance sur bourse' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'Bourses d''études versées' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Bourses d''études versées' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'Intérêts versés (Bourse individuel)' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêts versés (Bourse individuel)' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'SCEE versée (Collectif)' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'SCEE versée (Collectif)' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'SCEE versée (Individuel)' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'SCEE versée (Individuel)' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'BEC versée (Collectif)' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'BEC versée (Collectif)' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'BEC versée (Individuel)' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'BEC versée (Individuel)' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'Intérêt SCEE versée (Collectif)' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêt SCEE versée (Collectif)' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'Intérêt SCEE versée (Individuel)' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêt SCEE versée (Individuel)' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'Intérêt BEC versée (Collectif)' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêt BEC versée (Collectif)' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'Intérêt BEC versée (Individuel)' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêt BEC versée (Individuel)' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'Intérêt versé sur intérêt reçu d''un promoteur' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêt versé sur intérêt reçu d''un promoteur' THEN AN.vcAccountNumber
				ELSE ''
				END
				),
		'Intérêts sur RI reporté' = 
			MAX(
				CASE 
					WHEN A.vcAccount = 'Intérêts sur RI reporté' THEN AN.vcAccountNumber
				ELSE ''
				END
				)
	FROM UN_Account A
	JOIN UN_AccountNumber AN ON AN.iAccountID = A.iAccountID
	WHERE @EndDate BETWEEN AN.dtStart AND ISNULL(AN.dtEnd,GETDATE())
END
