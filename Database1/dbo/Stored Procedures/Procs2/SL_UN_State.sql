
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	SL_UN_State
Description 		:	PROCEDURE RETOURNANT LES PROVINCES/ÉTATS D'UN PAYS
Valeurs de retour	:	DataSet	

Notes :							05-05-2004 Dominic Létourneau	Migration de l'ancienne procedure selon les nouveaux standards
								06-05-2004 Dominic Létourneau	Modification pour permettre de retourner toutes les provinces si param vide
								10-05-2004 Dominic Létourneau	Modification pour enlever la sélection par pays et ajout de tous les champs de la table
				ADX0001278	IA	2007-03-16	Alain Quirion		Changement de nom SL_UN_State et suppresion du COnnectID
*********************************************************************************/
CREATE PROCEDURE dbo.SL_UN_State
AS
BEGIN
	-- Retourne les dossiers de la table de provinces
	SELECT 
		S.StateID,
		S.StateName,
		S.StateCode,
		S.StateTaxPct,
		C.CountryID,
		C.CountryName
	FROM Mo_State S
	LEFT JOIN Mo_Country C ON S.CountryID = C.CountryID
	ORDER BY S.StateName
END

