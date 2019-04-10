/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_GetGovernmentTransTypeDesc
Description 		:	Fonction qui retourne la description du GovernmentTransTypeID passé en paramètre
Valeurs de retour	:	Table temporaire
Note					:	ADX0000835	IA	2006-04-20	Bruno Lapointe	Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_GetGovernmentTransTypeDesc (
	@GovernmentTransTypeID INTEGER)
RETURNS VARCHAR(75)
AS
BEGIN
	RETURN
		CASE @GovernmentTransTypeID
			WHEN 0 THEN 'SCEE initialisé'
			WHEN 1 THEN 'Contrat'
			WHEN 2 THEN 'Contrat'
			WHEN 3 THEN 'Bénéficiaire'
			WHEN 4 THEN 'Souscripteur'
			WHEN 5 THEN 'Changement de bénéficiaire'
			WHEN 6 THEN 'Bénéficiaire (Mise à jour)'
			WHEN 7 THEN 'Souscripteur (Mise à jour)'
			WHEN 8 THEN 'Non attribué'
			WHEN 11 THEN 'Financière'
			WHEN 13 THEN 'Paiement d''aide aux études'
			WHEN 14 THEN 'EPS'
			WHEN 19 THEN 'Transfert IN'
			WHEN 20 THEN 'Contrat'
			WHEN 21 THEN 'Remboursement de subvention'
			WHEN 22 THEN 'Ajustement de résiliation'
			WHEN 23 THEN 'Transfert OUT'
		ELSE ''
		END
END

